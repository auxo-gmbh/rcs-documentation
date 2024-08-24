const {createSession} = require('./database');
const {databases, algorithms, queueSizes} = require('./constants');
const {
    extractAmountNodesByDB, extractAlgByDB, writeBarChartCsvFile, convertToRelativeTimestampMap,
    writeTimeChartCsvFile, writeBoxplotCsvFile
} = require("./utilities");

const BOXPLOT_QUERY = `
MATCH (statistics:Statistics)
WHERE statistics.queueSize=$queueSize
RETURN statistics.averageQueueOccupation as value
`
const getBoxplotDbResult = async (db, queueSize) => {
    const session = createSession(db);
    const queryResult = await session.run(BOXPLOT_QUERY, {queueSize});
    const result = queryResult.records.map(record => record.get(0))
    await session.close();
    return result;
}

const generateBoxplotData = async () => {
    for (const queueSize of queueSizes) {
        for (const db of databases) {
            const alg = extractAlgByDB(db)
            const amountNodes = extractAmountNodesByDB(db);
            const dbResult = await getBoxplotDbResult(db, queueSize);
            if (db.endsWith("-fail")) {
                writeBoxplotCsvFile(`data/load_distribution_boxplot/${alg}-n${amountNodes}-boxplot-qs${queueSize}-fail.csv`, dbResult);
                console.log(`Finished data/load_distribution_boxplot/${alg}-n${amountNodes}-boxplot-qs${queueSize}-fail.csv`)
            } else {
                writeBoxplotCsvFile(`data/load_distribution_boxplot/${alg}-n${amountNodes}-boxplot-qs${queueSize}.csv`, dbResult);
                console.log(`Finished data/load_distribution_boxplot/${alg}-n${amountNodes}-boxplot-qs${queueSize}.csv`)
            }
        }
    }
}

const run = async () => {
    await generateBoxplotData();
}

run().catch(console.error);
