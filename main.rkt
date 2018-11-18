#lang racket/base

;; The ANSI-Color display library makes it easy to display colorful content in terminals
;; that support ANSI colors.
;;
;; Based on www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html

(require "display.rkt")

(provide (all-from-out "display.rkt"))
