import http.client
import sys
import threading
import unittest
from http.server import HTTPServer
from unittest.mock import MagicMock, patch

# psycopg2 needs the C libpq driver; stub it out since these tests never hit a
# real database (app.get_db is mocked below).
sys.modules.setdefault("psycopg2", MagicMock())

import app


class TestApp(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = HTTPServer(("127.0.0.1", 0), app.Handler)
        cls.port = cls.server.server_address[1]
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.thread.join()

    def _get(self):
        conn = http.client.HTTPConnection("127.0.0.1", self.port)
        conn.request("GET", "/")
        resp = conn.getresponse()
        body = resp.read().decode()
        conn.close()
        return resp.status, body

    @patch("app.get_db")
    def test_returns_db_version_on_success(self, mock_get_db):
        mock_cursor = MagicMock()
        mock_cursor.fetchone.return_value = ("PostgreSQL 16.0",)
        mock_get_db.return_value.cursor.return_value = mock_cursor

        status, body = self._get()

        self.assertEqual(status, 200)
        self.assertIn("Hello from Docker!", body)
        self.assertIn("PostgreSQL 16.0", body)

    @patch("app.get_db", side_effect=Exception("connection refused"))
    def test_returns_error_message_when_db_unreachable(self, mock_get_db):
        status, body = self._get()

        self.assertEqual(status, 200)
        self.assertIn("DB Error", body)
        self.assertIn("connection refused", body)


if __name__ == "__main__":
    unittest.main()
