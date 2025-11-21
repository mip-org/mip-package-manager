from setuptools import setup, find_packages

setup(
    name='mip',
    version='0.1.0',
    description='pip-style package manager for MATLAB packages',
    author='Your Name',
    packages=find_packages(),
    include_package_data=True,
    package_data={
        'mip': ['+mip/*.m'],
    },
    entry_points={
        'console_scripts': [
            'mip=mip.__main__:main',
        ],
    },
    python_requires='>=3.6',
    install_requires=[
        'requests',
    ],
)