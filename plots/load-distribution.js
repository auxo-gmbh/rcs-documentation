const {createSession} = require('./database');
const {databases, algorithms, queueSizes} = require('./constants');
const {
    extractAmountNodesByDB, extractAlgByDB, writeBarChartCsvFile, convertToRelativeTimestampMap,
    writeTimeChartCsvFile
} = require("./utilities");

const BAR_QUERY = `
MATCH (statistics:Statistics)
WHERE statistics.queueSize=$queueSize
RETURN avg(statistics.averageQueueOccupation) as AQO,
sqrt(avg(statistics.varianceQueueOccupation)) as ASD,
avg(statistics.minQueueOccupation) as AMiQO,
avg(statistics.maxQueueOccupation) as AMaQO
`

const TIME_QUERY = `
MATCH (statistics:Statistics)
WHERE statistics.queueSize=$queueSize
WITH statistics
OPTIONAL MATCH (previousStatistics:Statistics)
WHERE previousStatistics.sentAt<=statistics.sentAt AND previousStatistics.queueSize=statistics.queueSize
WITH statistics.sentAt as timestamp, 
avg(previousStatistics.averageQueueOccupation) as AQO,
sqrt(avg(previousStatistics.varianceQueueOccupation)) as ASD,
avg(previousStatistics.minQueueOccupation) as AMiQO,
avg(previousStatistics.maxQueueOccupation) as AMaQO
RETURN timestamp, AQO, ASD,AMiQO,AMaQO
ORDER BY timestamp
`

const getBarDbResult = async (algorithm, failures, queueSize) => {
    const result = {};
    const filteredDbs =
        databases
            .filter(db => failures ? db.endsWith("-fail") : !db.endsWith("-fail"))
            .filter(db => db.startsWith(algorithm));
    for (const db of filteredDbs) {
        const amountNodes = extractAmountNodesByDB(db);
        const session = createSession(db);
        const queryResult = await session.run(BAR_QUERY, {queueSize});
        result[amountNodes] = queryResult.records[0].get(0);
        await session.close();
    }
    return result;
}

const getTimeDbResult = async (db, queueSize) => {
    const session = createSession(db);
    const queryResult = await session.run(TIME_QUERY, {queueSize});
    const result = queryResult.records
        .map(record => {
            const timestamp = record.get(0).toString();
            const averageQueueOccupation = record.get(1);
            return {timestamp, averageQueueOccupation};
        })
        .reduce((map, record) => {
            map[record.timestamp] = record.averageQueueOccupation;
            return map;
        }, {})
    await session.close();
    return convertToRelativeTimestampMap(result);
}

const generateBarChartData = async () => {
    for (const queueSize of queueSizes) {
        for (const alg of algorithms) {
            const dbResult = await getBarDbResult(alg, false, queueSize)
            writeBarChartCsvFile(`data/load_distribution/${alg}-qs${queueSize}.csv`, dbResult)

            const dbFailResult = await getBarDbResult(alg, true, queueSize)
            writeBarChartCsvFile(`data/load_distribution/${alg}-qs${queueSize}-fail.csv`, dbFailResult)
        }
    }
}

const generateTimeData = async () => {
    for (const queueSize of queueSizes) {
        for (const db of databases) {
            const alg = extractAlgByDB(db)
            const amountNodes = extractAmountNodesByDB(db);
            const dbResult = await getTimeDbResult(db, queueSize);
            if (db.endsWith("-fail")) {
                writeTimeChartCsvFile(`data/load_distribution/${alg}-n${amountNodes}-time-qs${queueSize}-fail.csv`, dbResult);
            } else {
                writeTimeChartCsvFile(`data/load_distribution/${alg}-n${amountNodes}-time-qs${queueSize}.csv`, dbResult);
            }
        }
    }
}

const run = async () => {
    await generateBarChartData();
    await generateTimeData();
}

run().catch(console.error);
