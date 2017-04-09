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

struct lr_server {
    int listenfd;
    int connfd;
    int port;
};

static int
ftp_set_socket_nonblocking(int fd)
{
  int rc, flags;

  /* get the socket flags */
  flags = fcntl(fd, F_GETFL, 0);
  if(flags == -1)
  {
    return -1;
  }

  /* add O_NONBLOCK to the socket flags */
  rc = fcntl(fd, F_SETFL, flags | O_NONBLOCK);
  if(rc != 0)
  {
    return -1;
  }

  return 0;
}

void server_start(struct lr_server *self)
{
    if(self->listenfd < 0) {
        struct sockaddr_in serv_addr;

        self->listenfd = socket(AF_INET, SOCK_STREAM, 0);
        memset(&serv_addr, '0', sizeof(serv_addr));

        serv_addr.sin_family = AF_INET;
#ifdef _3DS
        serv_addr.sin_addr.s_addr = gethostid();
        serv_addr.sin_port        = htons(self->port);
#else
        serv_addr.sin_addr.s_addr = INADDR_ANY;
        serv_addr.sin_port        = htons(self->port);
#endif

        bind(self->listenfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr));
        ftp_set_socket_nonblocking(self->listenfd);

        //int yes = 1;
        //setsockopt(self->listenfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(yes));

        listen(self->listenfd, 5);
    }

    if(self->listenfd >= 0) {
        self->connfd = accept(self->listenfd, (struct sockaddr*)NULL, NULL);

        if(self->connfd >= 0) {
            //closesocket(self->listenfd);
            //self->listenfd = -1;
            ftp_set_socket_nonblocking(self->connfd);
        }
    } else {
        self->connfd = -1;
    }
}
