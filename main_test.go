package main

import (
	"testing"

	"github.com/google/go-cmp/cmp"
)

func TestF1(t *testing.T) {
	F1()
}

func TestAdd(t *testing.T) {
	expected := 6
	if Add(2, 3) != expected {
		t.Fatalf("expected %d, got %d", expected, Add(2, 3))
	}

	if !cmp.Equal(Add(2, 3), expected) {
		t.Fatal("Error")
	}
}
