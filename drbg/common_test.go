package drbg

import (
	"crypto/aes"
	"crypto/sha256"
	"testing"
)

func TestGmCtrDrbgPrng(t *testing.T) {
	prng, err := NewGmCtrDrbgPrng(nil, 32, SECURITY_LEVEL_TEST, nil)
	if err != nil {
		t.Fatal(err)
	}
	data := make([]byte, 33)
	for i := 0; i < int(DRBG_RESEED_COUNTER_INTERVAL_LEVEL_TEST+1); i++ {
		n, err := prng.Read(data)
		if err != nil {
			t.Fatal(err)
		}
		if n != 33 {
			t.Errorf("not got enough random bytes")
		}
	}
}

func TestNistCtrDrbgPrng(t *testing.T) {
	prng, err := NewNistCtrDrbgPrng(aes.NewCipher, 16, nil, 16, SECURITY_LEVEL_TEST, nil)
	if err != nil {
		t.Fatal(err)
	}
	data := make([]byte, MAX_BYTES_PER_GENERATE+1)
	n, err := prng.Read(data)
	if err != nil {
		t.Fatal(err)
	}
	if n != MAX_BYTES_PER_GENERATE+1 {
		t.Errorf("not got enough random bytes")
	}
}

func TestGmHashDrbgPrng(t *testing.T) {
	prng, err := NewGmHashDrbgPrng(nil, 32, SECURITY_LEVEL_TEST, nil)
	if err != nil {
		t.Fatal(err)
	}
	data := make([]byte, 33)
	for i := 0; i < int(DRBG_RESEED_COUNTER_INTERVAL_LEVEL_TEST+1); i++ {
		n, err := prng.Read(data)
		if err != nil {
			t.Fatal(err)
		}
		if n != 33 {
			t.Errorf("not got enough random bytes")
		}
	}
}

func TestNistHashDrbgPrng(t *testing.T) {
	prng, err := NewNistHashDrbgPrng(sha256.New, nil, 32, SECURITY_LEVEL_TEST, nil)
	if err != nil {
		t.Fatal(err)
	}
	data := make([]byte, MAX_BYTES_PER_GENERATE+1)
	n, err := prng.Read(data)
	if err != nil {
		t.Fatal(err)
	}
	if n != MAX_BYTES_PER_GENERATE+1 {
		t.Errorf("not got enough random bytes")
	}
}

func TestGMSecurityStrengthValidation(t *testing.T) {
	_, err := NewGmHashDrbgPrng(nil, 24, SECURITY_LEVEL_TEST, nil)
	if err == nil {
		t.Fatalf("expected error here")
	}
	_, err = NewGmCtrDrbgPrng(nil, 24, SECURITY_LEVEL_TEST, nil)
	if err == nil {
		t.Fatalf("expected error here")
	}
}
