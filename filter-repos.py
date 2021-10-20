from argparse import ArgumentParser
from sys import exit
from json import loads


if __name__ == "__main__":

    _parser = ArgumentParser()
    _parser.add_argument('-N', type=str) 
    _parser.add_argument('-J', type=str)

    _parsed = _parser.parse_args()
    _jloads = loads(_parsed.J)['data']['viewer']['repositories']['nodes']
    _repos = [idx['nameWithOwner'].split('/')[1] for idx in _jloads]

    if _parsed.N in _repos:
        exit(1)

