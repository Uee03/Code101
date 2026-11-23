#include "loopback.h"

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "util.h"

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
typedef SOCKET ts_sock;
#define TS_BAD_SOCK INVALID_SOCKET
static void sock_close(ts_sock s) { closesocket(s); }
static bool sock_nonblocking(ts_sock s) {
    u_long on = 1;
    return ioctlsocket(s, FIONBIO, &on) == 0;
}
static bool would_block(void) { return WSAGetLastError() == WSAEWOULDBLOCK; }
#else
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
typedef int ts_sock;
#define TS_BAD_SOCK (-1)
static void sock_close(ts_sock s) { close(s); }
static bool sock_nonblocking(ts_sock s) {
    int flags = fcntl(s, F_GETFL, 0);
    return flags >= 0 && fcntl(s, F_SETFL, flags | O_NONBLOCK) == 0;
}
static bool would_block(void) { return errno == EAGAIN || errno == EWOULDBLOCK; }
#endif

#ifndef MSG_NOSIGNAL
#define MSG_NOSIGNAL 0
#endif

#define OVERALL_TIMEOUT_MS 180000u
#define CONNECTION_TIMEOUT_MS 3000u

struct ts_loopback {
    ts_sock listener;
    ts_sock conn;
    char request[2048];
    size_t request_len;
    char path[32];
    uint64_t deadline_ms;
    uint64_t conn_deadline_ms;
#ifdef _WIN32
    bool wsa_started;
#endif
};

/* Static pages: nothing from the request is ever copied into a response. */
static const char PAGE_OK[] =
    "<!doctype html><html><head><meta charset=\"utf-8\"><title>Signed in</title></head>"
    "<body><p>Sign-in finished. You can close this tab and return to the application.</p></body></html>";
static const char PAGE_NOT_FOUND[] = "<!doctype html><html><body><p>Not found.</p></body></html>";
static const char PAGE_BAD[] = "<!doctype html><html><body><p>Bad request.</p></body></html>";

static void reply(ts_sock s, int code, const char *reason, const char *body) {
    char head[384];
    size_t body_len = strlen(body);
    int n = snprintf(head, sizeof head,
                     "HTTP/1.1 %d %s\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %zu\r\n"
                     "Cache-Control: no-store\r\nReferrer-Policy: no-referrer\r\nX-Content-Type-Options: nosniff\r\n"
                     "Connection: close\r\n\r\n",
                     code, reason, body_len);
    if (n <= 0 || (size_t)n >= sizeof head) return;
    send(s, head, (int)n, MSG_NOSIGNAL); /* best effort: the page is tiny and the socket is fresh */
    send(s, body, (int)body_len, MSG_NOSIGNAL);
}

static void drop_connection(ts_loopback *lb) {
    if (lb->conn != TS_BAD_SOCK) {
        sock_close(lb->conn);
        lb->conn = TS_BAD_SOCK;
    }
    lb->request_len = 0;
}

ts_loopback *ts_loopback_open(const char *path, int *port_out) {
    ts_loopback *lb = ts_calloc(1, sizeof *lb);
    if (lb == NULL) return NULL;
    lb->listener = TS_BAD_SOCK;
    lb->conn = TS_BAD_SOCK;

    struct sockaddr_in addr;
    socklen_t addr_len = (socklen_t)sizeof addr;

#ifdef _WIN32
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
        ts_free(lb);
        return NULL;
    }
    lb->wsa_started = true;
#endif
    if (!ts_copy(lb->path, sizeof lb->path, path)) goto fail;
    lb->listener = socket(AF_INET, SOCK_STREAM, 0);
    if (lb->listener == TS_BAD_SOCK) goto fail;

    memset(&addr, 0, sizeof addr);
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK); /* 127.0.0.1, never 0.0.0.0 */
    addr.sin_port = 0;                             /* let the operating system choose a free port */
    if (bind(lb->listener, (struct sockaddr *)&addr, sizeof addr) != 0) goto fail;
    if (listen(lb->listener, 4) != 0) goto fail;
    if (getsockname(lb->listener, (struct sockaddr *)&addr, &addr_len) != 0) goto fail;
    if (!sock_nonblocking(lb->listener)) goto fail;

    *port_out = (int)ntohs(addr.sin_port);
    lb->deadline_ms = ts_now_ms() + OVERALL_TIMEOUT_MS;
    return lb;

fail:
    ts_loopback_close(lb);
    return NULL;
}

ts_lb_state ts_loopback_poll(ts_loopback *lb, char *query, size_t query_cap) {
    uint64_t now = ts_now_ms();
    if (now > lb->deadline_ms) return TS_LB_TIMEOUT;

    if (lb->conn != TS_BAD_SOCK && now > lb->conn_deadline_ms) drop_connection(lb); /* a silent pre-connect */
    if (lb->conn == TS_BAD_SOCK) {
        ts_sock c = accept(lb->listener, NULL, NULL);
        if (c == TS_BAD_SOCK) return would_block() ? TS_LB_PENDING : TS_LB_FAILED;
        if (!sock_nonblocking(c)) {
            sock_close(c);
            return TS_LB_FAILED;
        }
        lb->conn = c;
#ifdef SO_NOSIGPIPE /* macOS has no MSG_NOSIGNAL: a write to a closed peer must not kill the program */
        {
            int one = 1;
            setsockopt(c, SOL_SOCKET, SO_NOSIGPIPE, &one, sizeof one);
        }
#endif
        lb->request_len = 0;
        lb->conn_deadline_ms = now + CONNECTION_TIMEOUT_MS;
    }

    size_t room = sizeof lb->request - 1 - lb->request_len;
    if (room == 0) { /* 2 KiB without a complete request line: not a browser we want to talk to */
        reply(lb->conn, 400, "Bad Request", PAGE_BAD);
        drop_connection(lb);
        return TS_LB_PENDING;
    }
    int n = (int)recv(lb->conn, lb->request + lb->request_len, (int)room, 0);
    if (n < 0) {
        if (!would_block()) drop_connection(lb);
        return TS_LB_PENDING;
    }
    if (n == 0) { /* the peer closed without sending the request line */
        drop_connection(lb);
        return TS_LB_PENDING;
    }
    lb->request_len += (size_t)n;
    lb->request[lb->request_len] = '\0';

    char *eol = strstr(lb->request, "\r\n");
    if (eol == NULL) return TS_LB_PENDING; /* wait for more bytes */
    *eol = '\0';                           /* only the request line matters */

    char *target = strncmp(lb->request, "GET ", 4) == 0 ? lb->request + 4 : NULL;
    char *space = target != NULL ? strchr(target, ' ') : NULL;
    if (space == NULL) {
        reply(lb->conn, 400, "Bad Request", PAGE_BAD);
        drop_connection(lb);
        return TS_LB_PENDING;
    }
    *space = '\0';

    size_t path_len = strlen(lb->path);
    if (strncmp(target, lb->path, path_len) != 0 || (target[path_len] != '?' && target[path_len] != '\0')) {
        reply(lb->conn, 404, "Not Found", PAGE_NOT_FOUND); /* favicon.ico and friends */
        drop_connection(lb);
        return TS_LB_PENDING;
    }
    const char *q = target[path_len] == '?' ? target + path_len + 1 : "";
    bool fits = ts_copy(query, query_cap, q);
    reply(lb->conn, 200, "OK", PAGE_OK);
    drop_connection(lb);
    return fits ? TS_LB_DONE : TS_LB_FAILED;
}

void ts_loopback_close(ts_loopback *lb) {
    if (lb == NULL) return;
    drop_connection(lb);
    if (lb->listener != TS_BAD_SOCK) sock_close(lb->listener);
#ifdef _WIN32
    if (lb->wsa_started) WSACleanup();
#endif
    ts_free(lb);
}
