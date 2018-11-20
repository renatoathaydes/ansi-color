#lang racket/base

(require racket/match)

(provide color-display
         color-displayln
         with-colors
         background-color
         foreground-color)

;; Color and decoration escape definitions

(define reset "\033[0m")

(define (bkg-color256 code)
  (string-append "\033[48;5;" (number->string code) "m"))

(define (fore-color256 code)
  (string-append "\033[38;5;" (number->string code) "m"))

(define decoration-map
  #hasheq(
          (underline . "\033[4m")
          (bold . "\033[1m")
          (reversed . "\033[7m")))

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
          (b-white . "\033[37;1m")))

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
          (b-white . "\033[47;1m")))

;; customization parameters

(define background-color (make-parameter ""
  (lambda (arg) (as-escape-seq #t arg))))

(define foreground-color (make-parameter ""
  (lambda (arg) (as-escape-seq #f arg))))

(define no-reset (make-parameter #f))

;; implementation

(define (as-escape-seq bkg? arg)
  (define (raise-arg-error)
    (raise-arguments-error 'color
      "Cannot convert argument to color or style (not a valid symbol or integer in the 0-255 range)"
      "color"
      arg))
  (define map (if bkg? bkg-color-map fore-color-map))
  (match arg
    [(? null?) ""]
    ["" ""]
    [(? symbol? s) (hash-ref map s (lambda () (raise-arg-error)))]
    [(? integer? x)
      #:when (and (<= x 255) (>= x 0))
        ((if bkg? bkg-color256 fore-color256) x)]
    [_ (raise-arg-error)]))

(define (needs-reset? bkg fore)
  (cond [(no-reset) #f]
        [else (not (and (equal? "" bkg) (equal? "" fore)))]))

(define (color-display datum [out (current-output-port)])
  (let* ([bkg (background-color)]
         [fore (foreground-color)]
         [-reset (if (needs-reset? bkg fore) reset "")])
    (display (string-append bkg fore datum -reset) out)))

(define (color-displayln datum [out (current-output-port)])
  (color-display datum out)
  (newline out))

(define with-colors
  (case-lambda
    [(bkg-color fore-color proc)
     (parameterize ([background-color bkg-color]
                    [foreground-color fore-color]
                    [no-reset #t])
       (color-display "") ; sets the colors in the terminal
       (proc)             ; normal displays are colorized here
       (display reset))]  ; reset colors in the terminal
    [(fore-color proc)
     (with-colors null fore-color proc)]))


;; TESTS

(module+ test
    
  (require rackunit)

  (check-eq? (needs-reset? "" "") #f)
  (check-eq? (needs-reset? "red" "") #t)
  (check-eq? (needs-reset? "" "blue") #t)
  (check-eq? (needs-reset? "red" "green") #t)
  (check-eq? (parameterize ([no-reset #t])
              (needs-reset? "" "")) #f)
  (check-eq? (parameterize ([no-reset #t])
              (needs-reset? "red" "green")) #f)

  (define (wrap-in-color color text)
    (string-append (hash-ref fore-color-map color) text reset))

  (define (get-output proc)
    (let ([out (open-output-string)])
      (parameterize ([current-output-port out])
        (proc)
        (get-output-string out))))

  ; tests for color-display  
  (let ([hello-uncolored (get-output (lambda () (color-display "hello")))]
        [world-fore-red (get-output (lambda ()
                                      (parameterize ([background-color 'red])
                                        (color-display "world"))))]
        [tree-fore-blue (get-output (lambda ()
                                      (parameterize ([foreground-color 'blue])
                                        (color-display "tree"))))]
        [animal-yellow-black (get-output (lambda ()
                                          (parameterize ([background-color 'yellow]
                                                          [foreground-color 'black])
                                            (color-display "animal"))))])
    (check-equal? hello-uncolored "hello")
    (check-equal? world-fore-red "\033[41mworld\033[0m")
    (check-equal? tree-fore-blue "\033[34mtree\033[0m")
    (check-equal? animal-yellow-black "\033[43m\033[30manimal\033[0m"))

)
