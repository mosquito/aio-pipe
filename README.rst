AIO-PIPE
========

.. image:: https://travis-ci.org/mosquito/aio-pipe.svg
    :target: https://travis-ci.org/mosquito/aio-pipe
    :alt: Travis CI

.. image:: https://img.shields.io/pypi/v/aio-pipe.svg
    :target: https://pypi.python.org/pypi/aio-pipe/
    :alt: Latest Version

.. image:: https://img.shields.io/pypi/wheel/aio-pipe.svg
    :target: https://pypi.python.org/pypi/aio-pipe/

.. image:: https://img.shields.io/pypi/pyversions/aio-pipe.svg
    :target: https://pypi.python.org/pypi/aio-pipe/

.. image:: https://img.shields.io/pypi/l/aio-pipe.svg
    :target: https://pypi.python.org/pypi/aio-pipe/


Real asynchronous file operations with asyncio support.


Status
------

Development - BETA


Features
--------

* aio-pipe is a helper for POSIX pipes.


Code examples
-------------

Useful example.

.. code-block:: python

    import asyncio
    from aio_pipe import AsyncPIPE


    async def main(loop):
        p = AsyncPIPE(loop)

        for _ in range(1):
            await p.write(b"foo" * 1000)
            await p.read(3000)

        p.close()


    loop = asyncio.get_event_loop()
    loop.run_until_complete(main(loop))
