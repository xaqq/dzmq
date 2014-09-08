/**
 * Defines library's custom exceptions.
 * Authors: xaqq
 */
module dzmq.exceptions;

import std.exception;

class DZMQInternalError : Exception
{
    @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super("Internal library error: " ~ msg, file, line, next);
    }

    @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
    {
        super("Internal library error: " ~ msg, file, line, next);
    }
}
