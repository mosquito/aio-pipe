from libc.errno cimport errno
from posix cimport fcntl
from posix.unistd cimport close, pipe
from libc.stdio cimport fdopen, FILE
from cpython cimport bool, list


import asyncio
import os
from errno import errorcode


cpdef _create_future(loop):
    try:
        return loop.create_future()
    except AttributeError:
        return asyncio.Future(loop=loop)


cpdef _set_nonblock(int filedes):
    cdef int result
    cdef int error
    cdef int fd = filedes

    with nogil:
        result = fcntl.fcntl(fd, fcntl.F_SETFL, fcntl.O_NONBLOCK)

        if result != 0:
            error = errno

    if result != 0:
        raise SystemError(errorcode[error])


cpdef _create_pipe():
    cdef int[2] fds
    cdef int result
    cdef int error

    with nogil:
        result = pipe(fds)

        if result != 0:
            error = errno

    if result != 0:
        raise SystemError(errorcode[error])

    return fds[0], fds[1]


cpdef int _fdopen(int filedes, const char* mode):
    cdef FILE* file
    cdef int error

    with nogil:
        file = fdopen(filedes, mode)
        if file == NULL:
            error = errno

    if file == NULL:
        raise SystemError(errorcode[error])

    return filedes


cpdef _open_pipe(int read_fd, int write_fd):
    return _fdopen(read_fd, 'r'), _fdopen(write_fd, 'w')


cpdef _close_pipe(int filedes):
    cdef int fd = filedes
    cdef int result
    cdef int error

    with nogil:
        result = close(fd)
        if result != 0:
            error = errno

    if result != 0:
        raise SystemError(errorcode[error])


cdef class AsyncPIPE:
    cdef int _read_fd
    cdef int _write_fd
    cdef object _loop
    cdef bool _closed
    cdef list _pending_reads
    cdef list _pending_writes
    cdef bytes _read_buffer

    def __init__(self, loop=None, read_fd=None, write_fd=None):
        self._closed = False

        if not read_fd and not write_fd:
            self._read_fd, self._write_fd = _create_pipe()
        elif read_fd and write_fd:
            self._read_fd, self._write_fd = _open_pipe(read_fd, write_fd)
        else:
            raise ValueError('You should pass both read_fd and write_fd')

        _set_nonblock(self._read_fd)
        _set_nonblock(self._write_fd)

        self._pending_reads = []
        self._pending_writes = []
        self._read_buffer = b''

        self._loop = None

        if loop:
            self.loop = loop

    @property
    def loop(self):
        if self._loop is None:
            self._loop = asyncio.get_event_loop()

        return self._loop

    @loop.setter
    def loop(self, loop):
        if self._loop:
            self._loop.remove_reader(self._read_fd)
            self._loop.remove_writer(self._write_fd)

        self._loop = loop or asyncio.get_event_loop()
        self._loop.add_reader(self._read_fd, self._on_read)
        self._loop.add_writer(self._write_fd, self._on_write)

    @property
    def read_fd(self):
        return self._read_fd

    @property
    def write_fd(self):
        return self._write_fd

    cpdef read(self, unsigned int size):
        f = _create_future(self._loop)
        self._pending_reads.append((f, size))
        return f

    cpdef write(self, bytes data):
        f = _create_future(self._loop)
        self._pending_writes.append((f, data))
        return f

    def _on_read(self):
        try:
            self._read_buffer += os.read(self._read_fd, 1024)
        except BlockingIOError:
            return

        if not self._pending_reads:
            return

        future, size = self._pending_reads[0]

        if len(self._read_buffer) < size:
            return

        result, self._read_buffer = self._read_buffer[:size], self._read_buffer[size:]
        future.set_result(result)
        self._pending_reads.pop(0)

    def _on_write(self):
        if not self._pending_writes:
            return

        future, data = self._pending_writes[0]

        try:
            future.set_result(os.write(self._write_fd, data))
        except BlockingIOError:
            return
        else:
            self._pending_writes.pop(0)

    def close(self):
        if self._closed:
            return

        if self._loop:
            self._loop.remove_reader(self._read_fd)
            self._loop.remove_writer(self._write_fd)

        _close_pipe(self._read_fd)
        _close_pipe(self._write_fd)

        self._read_fd = -1
        self._write_fd = -1

        self._closed = True

    def __dealloc__(self):
        self.close()

    def __repr__(self):
        return "<AsyncPIPE(%r,%r)>" % (self.read_fd, self.write_fd)
