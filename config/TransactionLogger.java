package org.wallet.demo_wallet_service.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Component
public class TransactionLogger {

    private static final Logger TRANSACTION_LOGGER = LoggerFactory.getLogger("TRANSACTION_LOGGER");

    public void logDeposit(UUID walletId, BigDecimal amount, BigDecimal newBalance,
                           String requestId, boolean success, String message) {
        logTransaction("DEPOSIT", walletId, amount, newBalance, requestId, success, message);
    }

    public void logWithdrawal(UUID walletId, BigDecimal amount, BigDecimal newBalance,
                              String requestId, boolean success, String message) {
        logTransaction("WITHDRAW", walletId, amount, newBalance, requestId, success, message);
    }

    public void logBalanceCheck(UUID walletId, BigDecimal balance, String requestId) {
        // Более легковесный лог для read-only операций
        if (TRANSACTION_LOGGER.isInfoEnabled()) {
            String log = String.format(
                    "{\"operation\":\"BALANCE_CHECK\",\"walletId\":\"%s\",\"balance\":%s,\"requestId\":\"%s\",\"timestamp\":\"%s\"}",
                    walletId, balance, requestId, LocalDateTime.now()
            );
            TRANSACTION_LOGGER.info(log);
        }
    }

    private void logTransaction(String operation, UUID walletId, BigDecimal amount,
                                BigDecimal newBalance, String requestId,
                                boolean success, String message) {
        if (TRANSACTION_LOGGER.isInfoEnabled()) {
            String log = String.format(
                    "{\"operation\":\"%s\",\"walletId\":\"%s\",\"amount\":%s,\"newBalance\":%s,\"requestId\":\"%s\",\"success\":%s,\"message\":\"%s\",\"timestamp\":\"%s\"}",
                    operation, walletId, amount, newBalance, requestId, success, message, LocalDateTime.now()
            );

            if (success) {
                TRANSACTION_LOGGER.info(log);
            } else {
                TRANSACTION_LOGGER.error(log);
            }
        }
    }

    public void logConcurrentRetry(UUID walletId, int attempt, String requestId) {
        if (TRANSACTION_LOGGER.isWarnEnabled()) {
            String log = String.format(
                    "{\"event\":\"CONCURRENT_RETRY\",\"walletId\":\"%s\",\"attempt\":%d,\"requestId\":\"%s\",\"timestamp\":\"%s\"}",
                    walletId, attempt, requestId, LocalDateTime.now()
            );
            TRANSACTION_LOGGER.warn(log);
        }
    }
}