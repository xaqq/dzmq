/**
 * Module that declare ZeroMQ's C API functions.
 */
module dzmq.zmq;

extern(C)
{
  void	*zmq_ctx_new();
  int	zmq_ctx_term(void *context);

  void	*zmq_socket(void *context, int socket_type);
  int	zmq_close(void *socket);

  int	zmq_msg_init_size(zmq_msg_t *msg, size_t size);

  alias zmq_free_fn = void function(void *data, void *hint);
  int	zmq_msg_init_data (zmq_msg_t *msg, void *data, size_t size,
			   zmq_free_fn *ffn, void *hint);
  void	*zmq_msg_data(zmq_msg_t *msg);
  size_t zmq_msg_size(zmq_msg_t *msg);
  int	zmq_msg_send(zmq_msg_t *msg, void *socket, int flags);
  int	zmq_msg_close(zmq_msg_t *msg);

  int	zmq_connect(void *socket, const char *endpoint);
  int	zmq_bind(void *socket, const char *endpoint);

  /**
   * Definition of the zmq_msg_t struct from ZMQ code.
   */
  struct zmq_msg_t { ubyte[32] _; };
}
