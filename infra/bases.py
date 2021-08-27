"""
Provides better base classes for core CDK constructs

CDK constructs are so full of compromises that a puppy is sacrifised
every time a developer goes "Why?"
"""

from __future__ import annotations

import os
import typing
import collections
import re
import abc
import logging
import functools

import boto3

from aws_cdk import core


class Stack(abc.ABC):
    """
    Usage:
    ```
    class MyStack(Stack):
        def create_resources(self, scope):
            aws_cdk.aws_s3.Bucket(scope=scope, id='MyBucket')

    env = Environment.from_env_vars()

    stack = MyStack('foo', env=env)
    stack.create()

    another = MyStack('bar', env=env)
    another.create()
    ```
    """
    depends_on = []

    def __init__(self, name: str, env: Environment):
        self.name = name
        self.env = env
        self._skip_create = False

        for dep in self.depends_on:
            stack = self.env.get_stack(dep)
            if stack._skip_create:
                self.skip_create(f'Depends on `{dep}`')
                break

    @abc.abstractmethod
    def create_resources(self, scope: core.Construct) -> None:
        raise NotImplementedError

    def skip_create(self, msg: str=None):
        self._skip_msg = msg
        self._skip_create = True

    def create(self) -> Stack:
        self._stack = core.Stack(
            scope=self.env._app,
            id=self.name,
            env=self.env._env
        )
        if self._skip_create:
            # early return if app doesn't exist yet
            print("=" * 20)
            print(f"SKIPPING {self}: {self._skip_msg}")
            print("=" * 20)
            return self

        self.create_resources(scope=self._stack)
        return self

    def __repr__(self) -> str:
        return f'<Stack {self.__class__.__name__}("{self.name}")>'


class Environment:
    """
    Usage:
    ```
    class MyEnvironment(Environment):
        envs = {
            'dev': {'account': '12345', 'region': 'us-east-2'},
            'prod': {'account': '12345', 'region': 'ap-southeast-2'}
        }
        default_env = 'dev'
        stacks = [
            {
                'name': 'core',
                'stack': MyCoreStack,
                'envs': '.*'
            },
            {
                'name': 'poc',
                'stack': MyPOCStack,
                'envs': '(?!prod)'
            }
        ]

    env = MyEnvironment.from_env_var()
    env.synth()
    ```
    """

    envs: typing.ClassVar[typing.Dict[str, dict]]
    # example: {
    #   "dev": {"account": "12345", "region": "ap-southeast-2"}
    # }
    default_env: typing.ClassVar[str]
    # example: "dev"
    stacks: typing.ClassVar[typing.List[dict]]
    # example: [
    #   {"name": "core", "stack": MyStackClass, "envs": ".*"}
    # ]

    def __init__(self, name):
        self.name = name
        self.account = self.envs[name]['account']
        self.region = self.envs[name]['region']

        self._app = core.App()
        self._env = core.Environment(**self.envs[name])

        self._created = {}

    @classmethod
    def from_env_var(cls):
        name = os.environ.get('ENV', cls.default_env)
        return cls(name)

    def synth(self):
        self.add_stacks()
        return self._app.synth()

    def add_stacks(self):
        for s in self.stacks:
            if not self.should_create(s['envs']):
                continue

            self.create_stack(s['name'], s['stack'])

    def get_stack(self, name: str):
        return self._created[name]

    def should_create(self, valid_envs: str):
        match = re.match(valid_envs, self.name)
        if match is None:
            return False
        return True

    def create_stack(self, name: str, stack: typing.Type[Stack]) -> Stack:
        s = stack(
            f'{self.name}-{name}', # prepend environment name
            env=self
        ).create()
        self._created[name] = s
        logging.info(f'Created {s} in {self}')
        return s

    def __repr__(self):
        return f"<Environment {self.name} aws://{self.account}/{self.region}>"

    def get_provisioning_parameter(self, ssm_key: str):
        client = _get_ssm_client(profile='provisioning')

        return client.get_parameter(Name=ssm_key)['Parameter']['Value']

    def get_parameter(self, ssm_key: str):
        client = _get_ssm_client(profile=self.name)

        return client.get_parameter(Name=ssm_key)['Parameter']['Value']

    def get_boto3_session(self):
        return _get_boto3_session(profile=self.name)


@functools.lru_cache(maxsize=4)
def _get_boto3_session(profile: str):
    return boto3.session.Session(profile_name=profile)


@functools.lru_cache(maxsize=4)
def _get_ssm_client(profile: str):
    return _get_boto3_session(profile).client('ssm')

