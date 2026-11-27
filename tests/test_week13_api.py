"""Offline tests for the Week 13 read API."""
import importlib.util
import json
from decimal import Decimal
from pathlib import Path
from unittest.mock import MagicMock
import unittest


def get_module():
    spec = importlib.util.spec_from_file_location("handler", Path(__file__).resolve().parents[1] / "backend" / "handler.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


class ReadApiTest(unittest.TestCase):
    def setUp(self):
        self.m = get_module()
        self.m.table = lambda key: MagicMock()

    def test_reject_post(self):
        resp = self.m.lambda_handler({"requestContext": {"http": {"method": "POST"}}, "rawPath": "/graph"}, None)
        self.assertEqual(resp["statusCode"], 405)

    def test_unknown_route(self):
        resp = self.m.lambda_handler({"requestContext": {"http": {"method": "GET"}}, "rawPath": "/missing"}, None)
        self.assertEqual(resp["statusCode"], 404)

    def test_decimal_encoding(self):
        self.assertEqual(self.m.encode_decimal(Decimal("2")), 2)
        self.assertEqual(self.m.encode_decimal(Decimal("2.5")), 2.5)

    def test_long_skill_id(self):
        resp = self.m.lambda_handler({"requestContext": {"http": {"method": "GET"}}, "rawPath": "/graph",
                                     "queryStringParameters": {"skill_id": "x" * 81}}, None)
        self.assertEqual(resp["statusCode"], 400)

if __name__ == "__main__":
    unittest.main()
