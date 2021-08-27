import logging

from . import bases
from .stacks import (
    core
)

#from stacks import core


class Environment(bases.Environment):
    envs = {
        'game-provisioning': {
            'account': '625447474288',
            'region': 'ap-southeast-2'
        },
        'game-1': {
            'account': '625447474288',
            'region': 'ap-southeast-2'
        }
    }
    default_env = 'game-1'
    stacks = [
        {
            'name': 'core',
            'stack': core.Core,
            'envs': '(game)'
        }
    ]


def main():
    """main entry point for cdk"""
    logging.basicConfig(level='INFO')
    env = Environment.from_env_var()
    logging.info(f'Creating stacks in {env}')
    env.synth()
