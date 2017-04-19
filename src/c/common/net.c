#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <fcntl.h>
#include <errno.h>

#ifdef _WIN32
#include <winsock2.h>
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#endif

#ifdef _3DS
#include <3ds.h>
#include <malloc.h>
#endif

static bool lr_net_initted = false;
void net_init()
{
    if(lr_net_initted) {
        return;
    }
    lr_net_initted = true;
#ifdef _WIN32
	WSADATA data;
	WSAStartup(MAKEWORD(2, 0), &data);
#else
#endif
}

static void set_nonblocking(int fd)
{
#ifdef _WIN32
	u_long iMode = 1;
	ioctlsocket(fd, FIONBIO, &iMode);
#else
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
#endif
}

int server_start(int port)
{
    struct sockaddr_in serv_addr;
    memset(&serv_addr, '0', sizeof(serv_addr));
    serv_addr.sin_family = AF_INET;
#ifdef _3DS
    serv_addr.sin_addr.s_addr = gethostid();
    serv_addr.sin_port        = htons(port);
#else
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port        = htons(port);
#endif

    int listenfd = socket(AF_INET, SOCK_STREAM, 0);
    bind(listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
    set_nonblocking(listenfd);

    //int yes = 1;
    //setsockopt(self->listenfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

    listen(listenfd, 20);

    return listenfd;
}

#ifdef _3DS
#define log(fmt, ...) do{\
    char str[512];\
    sprintf(str, fmt, ## __VA_ARGS__);\
    svcOutputDebugString(str, strlen(str));\
}while(0)
#else
#define log(fmt, ...) printf(fmt"\n", ## __VA_ARGS__)
#endif

const char *lr_net_error = NULL;

int client_start(const char *ip, const char *port)
{
    struct sockaddr_in addr;
    size_t addrlen = sizeof(addr);

    int connfd = socket(AF_INET, SOCK_STREAM, 0);
    if(connfd < 0) {
        log("socket creation failed");
        return -1;
    }

    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_port = htons(atoi(port));
#ifdef _WIN32
	addr.sin_addr.s_addr = inet_addr(ip);
#else
    inet_aton(ip, &addr.sin_addr);
#endif

    int rc = connect(connfd, (struct sockaddr*)&addr, addrlen);

    if(rc > 0) {
#ifdef _WIN32
		lr_net_error = "cant get error cuz windows sucks";
#else
        lr_net_error = gai_strerror(rc);
#endif
        return -1;
    } else if(rc == -1) {
        lr_net_error = strerror(errno);
        return -1;
    }
    set_nonblocking(connfd);

    return connfd;
}

bool client_is_connected(int fd)
{
    // http://stackoverflow.com/questions/2597608/c-socket-connection-timeout
    // apparently this doesnt work in windows
#ifdef _WIN32
#warning nyi
	return true;
#else
    int status;
    size_t len = sizeof(status);

    getsockopt(fd, SOL_SOCKET, SO_ERROR, &status, &len);

    return status == 0;
#endif
}

int server_listen(int listenfd)
{
    int connfd = accept(listenfd, (struct sockaddr*)NULL, NULL);

    if(connfd >= 0) {
        set_nonblocking(connfd);
    }

    return connfd;
}
