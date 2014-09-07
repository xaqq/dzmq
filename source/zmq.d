/**
 * Module that declare ZeroMQ's C API functions.
 */
module zmq;

extern(C)
{
  void	*zmq_ctx_new();
  int	zmq_ctx_term(void *context);

  void	*zmq_socket(void *context, int socket_type);
  int	zmq_close(void *socket);
}
