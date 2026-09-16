def test_basic():
    assert 1 + 1 == 2

def test_response():
    response = b"Hello from Docker!"
    assert b"Hello" in response
    assert len(response) > 0
