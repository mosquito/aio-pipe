from setuptools import setup, Extension
from sys import platform


libraries = []


if platform in ('linux', 'darwin'):
    try:
        from Cython.Build import cythonize

        extensions = cythonize([
            Extension(
                "aio_pipe",
                ["aio_pipe.pyx"],
                libraries=libraries,
            ),
        ], force=True, emit_linenums=False)

    except ImportError:
        extensions = [
            Extension(
                "aio_pipe",
                ["aio_pipe.c"],
                libraries=libraries,
            ),
        ]
else:
    raise NotImplementedError('POSIX pipes are not supported on this system')


setup(
    name='aio-pipe',
    ext_modules=extensions,
    version='0.1.1',
    packages=[],
    license="Apache 2",
    description="POSIX Pipe async helper",
    long_description=open("README.rst").read(),
    platforms=["POSIX"],
    url='https://github.com/mosquito/aio-pipe',
    author="Dmitry Orlov",
    author_email="me@mosquito.su",
    build_requires=['cython'],
    keywords="posix pipe, python, asyncio, cython",
    classifiers=[
        'Development Status :: 4 - Beta',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'Intended Audience :: Education',
        'Intended Audience :: End Users/Desktop',
        'License :: OSI Approved :: Apache Software License',
        'Natural Language :: English',
        'Natural Language :: Russian',
        'Operating System :: POSIX :: Linux',
        'Operating System :: MacOS :: MacOS X',
        'Programming Language :: Cython',
        'Programming Language :: Python',
        'Programming Language :: Python :: 3 :: Only',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: Implementation :: CPython',
        'Topic :: Software Development :: Libraries',
        'Topic :: System',
        'Topic :: System :: Operating System',
    ],
)
