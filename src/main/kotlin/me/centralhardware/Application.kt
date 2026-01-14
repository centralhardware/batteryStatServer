package me.centralhardware

import com.clickhouse.jdbc.DataSourceImpl
import io.ktor.serialization.kotlinx.json.*
import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*
import io.ktor.server.plugins.contentnegotiation.*
import io.ktor.server.routing.*
import me.centralhardware.repository.BatteryRepository
import me.centralhardware.routes.batteryRoutes
import me.centralhardware.service.TelegramService
import org.flywaydb.core.Flyway
import org.slf4j.LoggerFactory
import java.util.Properties

fun main() {
    val logger = LoggerFactory.getLogger("Application")

    val clickhouseUrl = System.getenv("CLICKHOUSE_URL")
        ?: "jdbc:clickhouse://localhost:8123/default"
    val port = System.getenv("PORT")?.toIntOrNull() ?: 8080

    logger.info("Starting Battery Stats Server on port $port")
    logger.info("ClickHouse URL: $clickhouseUrl")

    logger.info("Running database migrations...")
    val ds = DataSourceImpl(clickhouseUrl, Properties())

    Flyway.configure()
        .dataSource(ds)
        .locations("classpath:db/migration", "filesystem:/app/resources/db/migration")
        .baselineOnMigrate(true)
        .load()
        .migrate()
    logger.info("Database migrations completed")

    val repository = BatteryRepository(clickhouseUrl)
    val telegramService = TelegramService()

    embeddedServer(Netty, port = port) {
        module(repository, telegramService)
    }.start(wait = true)
}

fun Application.module(repository: BatteryRepository, telegramService: TelegramService) {
    install(ContentNegotiation) {
        json()
    }

    routing {
        batteryRoutes(repository, telegramService)
    }
}
