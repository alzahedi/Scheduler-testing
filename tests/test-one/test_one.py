import os
import time



def test_simple():
    print("Starting test_simple")
    while True:
       time.sleep(1) 
    
    assert 1 == 1
    
def test_another():
    print("Starting test_another")
    assert 1 == 1