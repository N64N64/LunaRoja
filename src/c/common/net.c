#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <arpa/inet.h>
#include <fcntl.h>

#ifdef _3DS
#include <3ds.h>
#include <malloc.h>
#endif

static void set_nonblocking(int fd)
{
    int flags = fcntl(fd, F_GETFL, 0);
    fcntl(fd, F_SETFL, flags | O_NONBLOCK);
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

    listen(listenfd, 5);

    return listenfd;
}

// this doesnt work on 3DS
int client_start(const char *ip, const char *port)
{
    struct addrinfo hints, *res;

    // first, load up address structs with getaddrinfo():

    memset(&hints, 0, sizeof hints);
    hints.ai_family = AF_INET;  // use IPv4 or IPv6, whichever
    hints.ai_socktype = SOCK_STREAM;

    // we could put "80" instead on "http" on the next line:
    getaddrinfo(ip, port, &hints, &res);

    // make a socket:

    int connfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
    set_nonblocking(connfd);

    // connect it to the address and port we passed in to getaddrinfo():

    connect(connfd, res->ai_addr, res->ai_addrlen);

    return connfd;
}

bool client_is_connected(int fd)
{
    // http://stackoverflow.com/questions/2597608/c-socket-connection-timeout
    // apparently this doesnt work in windows

    int status;
    socklen_t len = sizeof(status);

    getsockopt(fd, SOL_SOCKET, SO_ERROR, &status, &len);

    return status == 0;
}

int server_listen(int listenfd)
{
    int connfd = accept(listenfd, (struct sockaddr*)NULL, NULL);

    if(connfd >= 0) {
        set_nonblocking(connfd);
    }

    return connfd;
}
