#lang racket/base

(require racket/match)

(provide color-display
         color-displayln
         ansi-color?
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

(define font-style (make-parameter ""
  (lambda (arg) (as-style-seq arg))))

(define no-reset (make-parameter #f))

;; implementation

(define (ansi-color? x)
  (or
      (and (integer? x) (<= x 255) (>= x 0))
      (and (symbol? x)  (hash-has-key? fore-color-map x))))

(define (as-escape-seq bkg? arg)
  (define (raise-arg-error)
    (raise-arguments-error 'color
      "Cannot convert argument to color (not a valid symbol or integer in the 0-255 range)"
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

(define (as-style-seq arg)
  (define (raise-arg-error)
    (raise-arguments-error 'style
      "Cannot convert argument to style (not a valid symbol)"
      "style"
      arg))
  (match arg
    ["" ""]
    [(? null?) ""]
    [(? symbol? s) (hash-ref decoration-map s (lambda () (raise-arg-error)))]
    [_ (raise-arg-error)]))

(define (needs-reset? bkg fore style)
  (cond [(no-reset) #f]
        [else (not (and (equal? "" bkg)
                        (equal? "" fore)
                        (equal? "" style)))]))

(define (color-display datum [out (current-output-port)])
  (let* ([bkg (background-color)]
         [fore (foreground-color)]
         [style (font-style)]
         [-reset (if (needs-reset? bkg fore style) reset "")])
    (display (string-append bkg fore style datum -reset) out)))

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
       (proc)
       (display reset))]  ; reset colors in the terminal
    [(fore-color proc)
     (with-colors null fore-color proc)]))


;; TESTS

(module+ test
    
  (require rackunit)

  (check-eq? (needs-reset? "" "" "") #f)
  (check-eq? (needs-reset? "red" "" "") #t)
  (check-eq? (needs-reset? "" "blue" "") #t)
  (check-eq? (needs-reset? "red" "green" "") #t)
  (check-eq? (needs-reset? "red" "green" "underline") #t)
  (check-eq? (needs-reset? "" "" "underline") #t)
  (check-eq? (parameterize ([no-reset #t])
              (needs-reset? "" "" "")) #f)
  (check-eq? (parameterize ([no-reset #t])
              (needs-reset? "red" "green" "reversed")) #f)
  
  (check-eq? (ansi-color? 'red) #t)
  (check-eq? (ansi-color? 'white) #t)
  (check-eq? (ansi-color? 'black) #t)
  (check-eq? (ansi-color? 'b-red) #t)
  (check-eq? (ansi-color? 'b-white) #t)
  (check-eq? (ansi-color? 'b-black) #t)
  (check-eq? (ansi-color? 'some) #f)
  (check-eq? (ansi-color? 'foo-bar) #f)
  (check-eq? (ansi-color? 0) #t)
  (check-eq? (ansi-color? 1) #t)
  (check-eq? (ansi-color? 10) #t)
  (check-eq? (ansi-color? 200) #t)
  (check-eq? (ansi-color? 255) #t)
  (check-eq? (ansi-color? 256) #f)
  (check-eq? (ansi-color? -1) #f)
  (check-eq? (ansi-color? -10) #f)
  (check-eq? (ansi-color? "blue") #f)
  (check-eq? (ansi-color? #t) #f)

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
                                            (color-display "animal"))))]
        [something-bold (get-output (lambda ()
                                      (parameterize ([font-style 'bold])
                                        (color-display "something"))))])
  
    (check-equal? hello-uncolored "hello")
    (check-equal? world-fore-red "\033[41mworld\033[0m")
    (check-equal? tree-fore-blue "\033[34mtree\033[0m")
    (check-equal? animal-yellow-black "\033[43m\033[30manimal\033[0m")
    (check-equal? something-bold "\033[1msomething\033[0m"))

  ; tests for with-colors
  (let ([blue-and-white (get-output (lambda () (with-colors 'blue 'white (lambda () (display "b-a-w")))))]
        [red-and-green  (get-output (lambda () (with-colors 'red 'green (lambda () (display "r-a-g")))))]
        [blue           (get-output (lambda () (with-colors 'blue (lambda () (display "b")))))]
        [white          (get-output (lambda () (with-colors 'white (lambda () (display "w")))))])

    (check-equal? blue-and-white "\033[44m\033[37mb-a-w\033[0m")
    (check-equal? red-and-green "\033[41m\033[32mr-a-g\033[0m")
    (check-equal? blue "\033[34mb\033[0m")
    (check-equal? white "\033[37mw\033[0m"))

)
