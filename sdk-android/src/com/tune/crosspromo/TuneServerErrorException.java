package com.tune.crosspromo;

/**
 * Exception for 500 requests
 */
class TuneServerErrorException extends Exception {
    private static final long serialVersionUID = -1190389199072822921L;

    public TuneServerErrorException(String msg) {
        super(msg);
    }
}
