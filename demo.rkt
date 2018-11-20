#lang racket

(require "display.rkt"
         racket/format)

;; This is a demo of the display module.
;;
;; It prints all 256 colors in rows of 16 colors.
;; One argument may be provided with the value:
;;   * -fore - colorize the foreground
;;   * -back - colorize the background
;; If no argument is provided, the background is colorized.

(define bkg?
  (let* ([args (current-command-line-arguments)]
         [arg (if (= (vector-length args) 1)
                 (vector-ref args 0)
                 "-back")])
    (cond [(equal? arg "-fore") #f]
          [(equal? arg "-back") #t]
          [else (error "Unrecognized option (choose '-back' or '-fore')" arg)])))

(define (fmt text)
  (~a #:min-width 6 #:align 'center text))

(for ([i (range 16)])
  (for ([j (range 16)])
    (define code (+ (* i 16) j))
    (define back (if bkg? code null))
    (define fore (if bkg? null code))
    (with-colors back fore (lambda () (display (fmt code)))))
    (newline))
