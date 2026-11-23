#pragma once

#include "net/Transport.hpp"

namespace tt {

// Transport on top of cpr (libcurl). Every call builds its own cpr::Session, so one object can be shared by threads.
class CprTransport final : public Transport {
public:
    Result<HttpResponse> send(const HttpRequest& request, std::stop_token stop) override;
};

}  // namespace tt
