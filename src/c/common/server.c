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

int server_listen(int listenfd)
{
    int connfd = accept(listenfd, (struct sockaddr*)NULL, NULL);

    if(connfd >= 0) {
        set_nonblocking(connfd);
    }

    return connfd;
}
