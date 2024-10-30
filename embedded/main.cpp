#include <iostream>
#include <string>

#include <emscripten/bind.h>

#include "R.h"
#include "Rinternals.h"
#include "Rembedded.h"
#include "Rinterface.h"
#include "R_ext/Parse.h"

std::string evaluate_expression(const std::string& code) {
    ParseStatus status;
    SEXP expr = PROTECT(Rf_allocVector(STRSXP, 1));
    SET_STRING_ELT(expr, 0, Rf_mkChar(code.c_str()));
    SEXP parsed = PROTECT(R_ParseVector(expr, -1, &status, R_NilValue));
    if (status != PARSE_OK) {
        std::cerr << "Failed to parse expression: " << code << std::endl;
        return "no result";
    }

    // std::cout << "[MAIN] printing value" << std::endl;
    // PrintValue(VECTOR_ELT(parsed, 0));
    // SEXP list = PROTECT(findVar(Rf_install("list"), R_BaseEnv));
    // std::cout << "[MAIN] printing list" << std::endl;
    // // PrintValue(list);
    // std::cout << TYPEOF(list) << std::endl;
    // SEXP list2 = PROTECT(Rf_eval(list, R_GlobalEnv));
    // std::cout << "[MAIN] printing list2" << std::endl;
    // // PrintValue(list2);
    // std::cout << TYPEOF(list2) << std::endl;


    SEXP result = PROTECT(Rf_eval(VECTOR_ELT(parsed, 0), R_GlobalEnv));

    std::string result_string{};
    if (TYPEOF(result) == REALSXP) {
        double res = REAL(result)[0];
        result_string = std::to_string(res);
    } else if (TYPEOF(result) == INTSXP) {
        int res = INTEGER(result)[0];
        result_string = std::to_string(res);
    } else if (TYPEOF(result) == STRSXP) {
        const char* res = CHAR(STRING_ELT(result, 0));
        result_string = res;
    } else {
        result_string = "unsupported result";
    }
    std::cout << "[MAIN] Printing results..." << std::endl;
    Rf_PrintValue(result);

    UNPROTECT(3); // expr, parsed, result
    return result_string;
}

int main(int argc, char *argv[]) {

    R_Outputfile = NULL;
    R_Consolefile = NULL;

    std::string code = "sqrt(9)";
    std::cout << "[MAIN] Running R code: " << code << std::endl;

    char *r_argv[] = {
        (char*)("R"),
        (char*)("--no-readline"),
        (char*)("--vanilla")
    };
    int r_argc = sizeof(r_argv) / sizeof(r_argv[0]);

    std::cout << "[MAIN] Initializing embedded R..." << std::endl;
    Rf_initEmbeddedR(r_argc, r_argv);

    std::string result = evaluate_expression(code);
    std::cout << "[MAIN] Result: " << result << std::endl;

    std::cout << "EVAL " << evaluate_expression("d1 <- 4") << std::endl;
    std::cout << "EVAL " << evaluate_expression("d2 <- 5") << std::endl;
    std::cout << "EVAL " << evaluate_expression("d1 + d2") << std::endl;
    Rf_endEmbeddedR(0);

    std::cout << "[MAIN] Done!" << std::endl;
    return 0;
}

float lerp(float a, float b, float t) {
    return (1 - t) * a + t * b;
}

EMSCRIPTEN_BINDINGS(my_module) {
    emscripten::function("lerp", &lerp);
    emscripten::function("evaluate_expression", &evaluate_expression);
}