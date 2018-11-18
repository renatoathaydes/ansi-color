#lang racket/base

(provide color-display
         color-displayln
         with-colors
         background-color
         foreground-color)

;; Color and decoration escape definitions

(define reset "\033[0m")

(define (color256 code)
  (string-append "\033[38;5;" (number->string code) "m"))

(define fore-color-map
  #hasheq(
          (black . "\033[30m")
          (red . "\033[31m")
          (green . "\033[32m")
          (yellow . "\033[33m")
          (blue . "\033[34m")
          (magenta . "\033[35m")
          (cyan . "\033[36m")
          (white . "\033[37m")
          (b-black . "\033[30;1m")
          (b-red . "\033[31;1m")
          (b-green . "\033[32;1m")
          (b-yellow . "\033[33;1m")
          (b-blue . "\033[34;1m")
          (b-magenta . "\033[35;1m")
          (b-cyan . "\033[36;1m")
          (b-white . "\033[37;1m")
          (underline . "\033[4m")
          (bold . "\033[1m")
          (reversed . "\033[7m")
          (() . "")))

(define bkg-color-map
  #hasheq(
          (black . "\033[40m")
          (red . "\033[41m")
          (green . "\033[42m")
          (yellow . "\033[43m")
          (blue . "\033[44m")
          (magenta . "\033[45m")
          (cyan . "\033[46m")
          (white . "\033[47m")
          (b-black . "\033[40;1m")
          (b-red . "\033[41;1m")
          (b-green . "\033[42;1m")
          (b-yellow . "\033[43;1m")
          (b-blue . "\033[44;1m")
          (b-magenta . "\033[45;1m")
          (b-cyan . "\033[46;1m")
          (b-white . "\033[47;1m")
          (() . "")))

;; customization parameters

; The background color to use to display text when using `color-display` and `color-displayln`.
(define background-color (make-parameter null))

; The foreground color or decoration to use to display text when using `color-display`
; and `color-displayln`.
(define foreground-color (make-parameter null))

(define no-reset (make-parameter #f))

;; implementation

; Like `display`, but using the parameters `background-color` and `foreground-color` to colorize
; and style the output.
(define (color-display datum [out (current-output-port)])
  (let* ([bkg  (hash-ref bkg-color-map (background-color))]
         [fore (hash-ref fore-color-map (foreground-color))]
         [-reset (if (no-reset) "" reset)])
    (display (string-append bkg fore datum -reset) out)))

; Like `color-display`, but prints a new-line at the end.
(define (color-displayln datum [out (current-output-port)])
  (color-display datum out)
  (displayln "" out))

; Sets the foreground and, optionally, the background color to be used to display text
; with the conventional `display` and `displayln` functions.
; Using `color-display` or `color-displayln` within the given `proc` causes the colors to
; be reset, thus should be avoided.
(define with-colors
  (case-lambda
    [(bkg-color fore-color proc)
     (parameterize ([background-color bkg-color]
                    [foreground-color fore-color]
                    [no-reset #t])
       (color-display "")
       (proc)
       (display reset))]
    [(fore-color proc) (with-colors null fore-color proc)]))

(color-displayln "Default color output")
(displayln "simple text")

(with-colors 'red 'blue
  (λ () (display "Red Blue\nOver multiple\nlines")))

(displayln "\nsimple text")

(with-colors null null
  (λ () (displayln "No colors")))

(displayln "simple text")

(color-displayln "Color output")

(with-colors 'b-yellow 'b-red
  (λ () (displayln "Yellow Red")))

(with-colors 'green 'black
  (λ () (displayln "Green Black")))
