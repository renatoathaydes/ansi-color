#lang info
(define collection "ansi-color")
(define deps '("base"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib"))
(define pkg-desc "A library to make it easy to colorize terminal output using ANSI escape sequences")
(define version "0.1")
(define pkg-authors '(renato-athaydes))
(define scribblings '(("scribblings/ansi-color.scrbl" ())))
(define clean '("compiled" "doc" "doc/ansi-color"))