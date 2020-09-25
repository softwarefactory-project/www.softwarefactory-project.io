Python Dataclasses
##################

:date: 2020-09-28
:category: blog
:authors: tristanC

This is a demonstration of how to use python dataclasses to build a Zuul client that
shows build information from a REST api.


Introduction
============

Python `dataclasses <https://docs.python.org/3/library/dataclasses.html>`_
provides many advantages over traditional datastructure such as *dict* or *object*.
Before we use them, let's take a look at **typing**, **immutability** and **parsing**.


Typing
======

Python `typing <https://docs.python.org/3/library/typing.html>`_
may be used to improve code readability.

.. code:: python

    def show_build(build):
        ...

This *show_build* function definition does not indicate what it does:

- Is the input a build id or a build dict ?

- Does it call print or does it return something ?

An annotated version would look like this:

.. code:: python

    def show_build(build: Build) -> str:
        ...

This annotated function definition tells us a lot more about its purpose.

Such functions can be checked automatically using a type checker like *mypy*.
In another terminal, you would start the typechecker like so:

.. code:: shell

    while inotifywait -e close_write *.py; do clear; mypy *.py; done

Then *mypy* would be acting as an assistant that ensures
the codes  match the signature.
This process greatly reduces the early test feedback loop
as we don't have to wait for a runtime execution.

Thus, it's not surprising to see companies like Dropbox adding
type annotation to their code-base:
`Our journey to type checking 4 million lines of Python <https://dropbox.tech/application/our-journey-to-type-checking-4-million-lines-of-python>`_


Immutability
============

Immutable records augment what one should expect from an object
and they reduce the number of states.
Each time a mutation is made, it creates a before and after state.

For example let's consider this *Build* implementation:

.. code:: python

    class Build:
        def __init__(self):
            self.job_name = None
            self.result = None
            ...

        def fromJson(self, dict):
            self.job_name = dict['job_name']
            self.result = dict['result']

*Build* has at least two states, and users need to ensure
it is in the correct state before using it efficiently.

Before looking at how **dataclasses** can leverage *typing*
and *immutability*, we'll look at one more concept: *parsing*


Parsing
=======

`Parse, don’t validate <https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/>`_
design is a great companion to typing and immutability.

Instead of implementing a validation layer,
we can focus on parsing immutable dataclasses.

First, some functions to parse an input and produce an optional output:

.. code:: python

    from typing import Optional
    from datetime import datetime
    import math

    def parse_str(s: str) -> Optional[str]:
        if len(s) > 0:
            return s
        return None

    def parse_isodate(s: str) -> Optional[datetime]:
        try:
            return datetime.strptime(s, "%Y-%m-%dT%H:%M:%S")
        except ValueError:
            return None

    def parse_float(s: float) -> Optional[float]:
        if not math.isnan(s):
            return s
        return None

Then, using a bit of typelevel abstraction, a couple of functions to run the parsers:

.. code:: python

    from typing import Callable, Optional, TypeVar, List

    Input = TypeVar('Input')
    Output = TypeVar('Output')

    def run(parser: Callable[[Input], Optional[Output]], input_value: Input) -> Output:
        result = parser(input_value)
        if result is None:
            raise RuntimeError("Expected %s, got: %s" % (parser.__name__, input_value))
        return result

    def run_many(parser: Callable[[Input], Optional[Output]], input_values: List[Input]) -> List[Output]:
        return [run(parser, input_value) for input_value in input_values]

We are now ready to implement the Zuul client.

Zuul build dataclass
====================

A Zuul build dataclass can be written as:

.. code:: python

    from dataclasses import dataclass

    @dataclass(frozen=True)
    class BuildArtifact:
        name: str
        url: str

    @dataclass(frozen=True)
    class Build:
        job_name: str
        result: str
        duration: float
        start_time: datetime
        artifacts: List[BuildArtifact]

    def show_build(build: Build) -> str:
        return "\n".join([
            "# Build: " + str(build.job_name),
            "result: " + build.result,
            "date: " + str(build.start_time),
            "duration: " + str(build.duration),
            "",
            "## Artifacts:"
        ] + list(map(show_artifacts, build.artifacts)))

    def show_artifacts(artifact: BuildArtifact) -> str:
        return "\n".join([
            "* name: " + artifact.name,
            "  url: " + artifact.url])

To create the Build dataclass, a parser can be written as:

.. code:: python

    from typing import Any, Dict

    def parse_artifact(json_obj: Dict[str, Any]) -> Optional[BuildArtifact]:
        try:
          return BuildArtifact(
            run(parse_str, json_obj['name']),
            run(parse_str, json_obj['url'])
          )
        except RuntimeError:
          return None

    def parse_build(json_obj: Dict[str, Any]) -> Optional[Build]:
        try:
          return Build(
            run(parse_str, json_obj['job_name']),
            run(parse_str, json_obj['result']),
            run(parse_float, json_obj['duration']),
            run(parse_isodate, json_obj['start_time']),
            run_many(parse_artifact, json_obj['artifacts']),
          )
        except RuntimeError:
          return None

    def build_from_json(json_obj: Any) -> Build:
        return run(parse_build, json_obj)


And the rest of the client implementation is:

.. code:: python

    import argparse
    import requests

    def read_json(url: str):
        import requests
        return requests.get(url).json()

    def main() -> None:
        parser = argparse.ArgumentParser()
        parser.add_argument("--build-url")
        parser.add_argument("--pretty", action="store_true")
        args = parser.parse_args()
        build = build_from_json(read_json(args.build_url))
        print(show_build(build) if args.pretty else build)

    if __name__ == "__main__":
        main()


Using dataclasses-json and argparse-dataclass
==============================================

Some convenient external libraries are available to work with dataclasses.
The above implementation may be simplified like so:

.. code:: python

    from dataclasses import dataclass
    from datetime import datetime
    from typing import List
    from uuid import UUID
    from dataclasses_json import dataclass_json, Undefined # type: ignore
    from argparse_dataclass import ArgumentParser # type: ignore

    @dataclass(frozen=True)
    class BuildArtifact:
        name: str
        url: str

    @dataclass_json(undefined=Undefined.EXCLUDE)
    @dataclass(frozen=True)
    class Build:
        uuid: UUID
        job_name: str
        result: str
        duration: float
        artifacts: List[BuildArtifact]

    def show_build(build: Build) -> str:
        return "\n".join([
            "# Build: " + str(build.uuid),
            "name: " + build.job_name,
            "duration: " + str(build.duration),
            "",
            "## Artifacts:"
        ] + list(map(show_artifacts, build.artifacts)))

    def show_artifacts(artifact: BuildArtifact) -> str:
        return "\n".join([
            "* name: " + artifact.name,
            "  url: " + artifact.url])

    @dataclass
    class BuildCLI:
        pretty_print: bool
        zuul_url: str
        tenant: str
        id: str

    def read_json(url: str):
        import requests
        return requests.get(url).json()

    def build_url(args: BuildCLI) -> str:
        return args.zuul_url + "/api/tenant/" + args.tenant + "/build/" + args.id

    def main() -> None:
        import requests
        args = ArgumentParser(BuildCLI).parse_args()
        build = Build.from_dict(read_json(build_url(args)))  # type: ignore
        if args.pretty_print:
            print(show_build(build))
        else:
            print(build)

    if __name__ == "__main__":
        # Install these requirements first:
        #   python3 -m pip install --user argparse-dataclass dataclasses-json requests
        # Demo:
        #   python3 dataclass.py --zuul-url https://zuul.opendev.org/ --tenant zuul --id e142dd27c4554397b3cdbf8bb4f68224
        main()
