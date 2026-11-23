#pragma once

#include <spdlog/spdlog.h>

#include <condition_variable>
#include <deque>
#include <exception>
#include <functional>
#include <mutex>
#include <stop_token>
#include <thread>
#include <utility>
#include <vector>

namespace tt {

// Worker threads never touch UI state. They post closures here; the UI thread runs them once per frame.
class UiQueue {
public:
    using Task = std::function<void()>;

    void post(Task task) {
        const std::lock_guard lock{mutex_};
        tasks_.push_back(std::move(task));
    }

    // UI thread only. Takes the whole batch under the lock and runs it without the lock, so a task may post again.
    void drain() {
        std::deque<Task> batch;
        {
            const std::lock_guard lock{mutex_};
            batch.swap(tasks_);
        }
        for (auto& task : batch) {
            task();
        }
    }

private:
    std::mutex mutex_;
    std::deque<Task> tasks_;
};

// A small pool of std::jthread workers. Destroying the pool requests stop and joins every thread;
// jobs that were still waiting in the queue are dropped.
class Worker {
public:
    using Job = std::function<void(std::stop_token)>;

    explicit Worker(unsigned threadCount = 2) {
        for (unsigned i = 0; i < threadCount; ++i) {
            threads_.emplace_back([this](std::stop_token shutdown) { run(shutdown); });
        }
    }
    Worker(const Worker&) = delete;
    Worker& operator=(const Worker&) = delete;
    ~Worker() {
        for (auto& thread : threads_) {
            thread.request_stop();
        }
        // The jthread members are destroyed first (declared last) and join here.
    }

    // `cancel` stops this one job; the pool's own stop request (shutdown) always applies as well.
    void submit(Job job, std::stop_token cancel = {}) {
        {
            const std::lock_guard lock{mutex_};
            queue_.push_back(Item{std::move(job), std::move(cancel)});
        }
        wake_.notify_one();
    }

private:
    struct Item {
        Job job;
        std::stop_token cancel;
    };

    void run(std::stop_token shutdown) {
        while (true) {
            Item item;
            {
                std::unique_lock lock{mutex_};
                if (!wake_.wait(lock, shutdown, [this] { return !queue_.empty(); })) {
                    return;  // stop requested and nothing to do
                }
                item = std::move(queue_.front());
                queue_.pop_front();
            }
            std::stop_source merged;
            const std::stop_callback onShutdown{shutdown, [&merged] { merged.request_stop(); }};
            const std::stop_callback onCancel{item.cancel, [&merged] { merged.request_stop(); }};
            try {
                item.job(merged.get_token());
            } catch (const std::exception& error) {
                spdlog::error("background job failed: {}", error.what());
            } catch (...) {
                spdlog::error("background job failed with an unknown exception");
            }
        }
    }

    std::mutex mutex_;
    std::condition_variable_any wake_;
    std::deque<Item> queue_;
    std::vector<std::jthread> threads_;
};

}  // namespace tt
