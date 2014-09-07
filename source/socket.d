import message;

class Socket
{
	this()
	{}

  bool write(Message m)
  {
    return true;
  }
}

unittest
  {
    auto s = new Socket();
    assert(s.write(null));
  }
