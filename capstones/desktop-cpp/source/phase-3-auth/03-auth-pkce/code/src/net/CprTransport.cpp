#include "net/CprTransport.hpp"

#include <cpr/cpr.h>
#include <spdlog/spdlog.h>

#include <chrono>
#include <cstdint>

namespace tt {
namespace {

const char* methodName(Method method) {
    switch (method) {
        case Method::Get: return "GET";
        case Method::Post: return "POST";
        case Method::Put: return "PUT";
        case Method::Patch: return "PATCH";
        case Method::Delete: return "DELETE";
    }
    return "?";
}

cpr::Response perform(cpr::Session& session, Method method) {
    switch (method) {
        case Method::Post: return session.Post();
        case Method::Put: return session.Put();
        case Method::Patch: return session.Patch();
        case Method::Delete: return session.Delete();
        case Method::Get: break;
    }
    return session.Get();
}

}  // namespace

Result<HttpResponse> CprTransport::send(const HttpRequest& request, std::stop_token stop) {
    cpr::Session session;
    session.SetUrl(cpr::Url{request.url});
    cpr::Header headers;
    for (const auto& [name, value] : request.headers) {
        headers[name] = value;
    }
    session.SetHeader(headers);
    session.SetTimeout(cpr::Timeout{request.timeout});
    session.SetConnectTimeout(cpr::ConnectTimeout{std::chrono::milliseconds{3000}});
    session.SetRedirect(cpr::Redirect(false));
    // libcurl calls this regularly during a transfer; returning false aborts it (clean shutdown, cancel).
    session.SetProgressCallback(cpr::ProgressCallback{
        [&stop](auto, auto, auto, auto, std::intptr_t) { return !stop.stop_requested(); }});
    if (!request.body.empty()) {
        session.SetBody(cpr::Body{request.body});
    }

    cpr::Response reply = perform(session, request.method);
    if (reply.error.code == cpr::ErrorCode::ABORTED_BY_CALLBACK) {
        return failure(ErrorKind::Cancelled, "Cancelled");
    }
    if (reply.error.code != cpr::ErrorCode::OK) {
        return failure(ErrorKind::Network, "Cannot reach the server", reply.error.message);
    }
    spdlog::debug("{} {} -> {}", methodName(request.method), request.url, reply.status_code);

    HttpResponse response;
    response.status = static_cast<int>(reply.status_code);
    response.body = std::move(reply.text);
    for (const auto& [name, value] : reply.header) {
        response.headers.emplace(name, value);
    }
    return response;
}

}  // namespace tt
