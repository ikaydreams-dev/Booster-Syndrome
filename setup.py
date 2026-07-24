from setuptools import setup, find_packages

setup(
    name="booster-syndrome",
    version="1.0.0",
    author="ikaydreams108@gmail.com",
    description="Multi-language microservices architecture",
    packages=find_packages(),
    install_requires=[
        "numpy>=1.24.0",
        "pandas>=2.0.0",
        "flask>=2.3.0",
        "pytest>=7.4.0",
    ],
    python_requires=">=3.10",
)
