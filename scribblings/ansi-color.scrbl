#lang scribble/manual
@require[@for-label[racket
                    ansi-color]]

@title{ansi-color}
@author{renato-athaydes}

@defmodule[ansi-color]

A library to make it easy to colorize terminal output using ANSI escape sequences.

@hyperlink["https://github.com/renatoathaydes/ansi-color" "Source"].

@[table-of-contents]

@section{Quick Reference}

The following code samples show how to use the basic functions of this library:

@#reader scribble/comment-reader
(racketblock
;; set the parameters used to colorize output...
;; if not set, the output is not colorized!
(background-color 'black)
(foreground-color 'green)

;; display "Hello world" with the current parameters (i.e. green on black)
(color-display "Hello world")

;; with explicit parameters
(parameterize ([background-color 'white]
               [foreground-color 'blue])
    (color-display "This is blue on white"))

;; using the more convenient helper function, `with-colors`
(with-colors 'white 'blue
    (lambda () (displayln "This is also blue on white")))
)

@;--------------------------------------------------------------------

@section{Parameters}

@defparam[background-color color ansi-color?]{
  Defines the background color that is used by @racket[color-display] and @racket[color-displayln].
}

@defparam[foreground-color color ansi-color?]{
  Defines the foreground color that is used by @racket[color-display] and @racket[color-displayln].
}

@;--------------------------------------------------------------------

@section{Functions}

datum : any/c
  out : output-port? = (current-output-port)

@defproc[(color-display [datum any/c] [out output-port? (current-output-port)]) void?]{
Like @racket[display], but using the parameters @racket[background-color] and @racket[foreground-color] to colorize
and style the output.
}

@defproc[(color-displayln [datum any/c] [out output-port? (current-output-port)]) void?]{
Like @racket[displayln], but using the parameters @racket[background-color] and @racket[foreground-color] to colorize
and style the output.
}

@defproc*[([(with-colors [bkg-color ansi-color?] [fore-color ansi-color?] [proc (-> any)]) void?]
           [(with-colors [fore-color ansi-color?] [proc (-> any)]) void?])]{
Sets the foreground and, optionally, the background color to be used to display text
with the conventional @racket[display] and @racket[displayln] functions.
Using @racket[color-display] or @racket[color-displayln] within the given @racket[proc] causes the colors to
be reset, and thus should be avoided.
}
