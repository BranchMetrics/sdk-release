package com.tune.crosspromo;

/**
 * Exception for 400 requests
 */
class TuneBadRequestException extends Exception {
    private static final long serialVersionUID = -7430171594303814521L;

    public TuneBadRequestException(String msg) {
        super(msg);
    }
}
