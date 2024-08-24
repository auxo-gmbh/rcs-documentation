const {databases, algorithms} = require("./constants");
const {
    writeBarChartCsvFile, extractAmountNodesByDB, extractAlgByDB, writeTimeChartCsvFile,
    convertToRelativeTimestampMap
} = require("./utilities");
const {createSession} = require("./database");

const ACO_RW_BAR_QUERY = `
MATCH (:Device)-[response:SENT_TO {details: 'RESPONSE'}]->(:Device)-[offloaded:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WHERE offloaded.requestId = response.requestId
RETURN avg(response.sentAt-offloaded.sentAt) as value
`;

const GOSSIPS_BAR_QUERY = `
MATCH (:Device)-[response:SENT_TO {details: 'RESPONSE'}]->(:Device)-[offloaded:SENT_TO {details: 'GOSSIPS_DISCOVERY_REQUEST'}]->(:Device)
WHERE offloaded.requestId = response.requestId AND response.path=[]
WITH offloaded.requestId as reqID, min(offloaded.sentAt) as reqTime, max(response.sentAt) as resTime
RETURN avg(resTime-reqTime) as value
`;

const ACO_RW_TIME_QUERY = `
MATCH (:Device)-[response:SENT_TO {details: 'RESPONSE'}]->(:Device)-[offloaded:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WHERE offloaded.requestId = response.requestId
WITH response.sentAt as time
OPTIONAL MATCH (:Device)-[response:SENT_TO {details: 'RESPONSE'}]->(:Device)-[offloaded:SENT_TO {details: 'OFFLOADED'}]->(:Device)
WHERE offloaded.requestId = response.requestId AND response.sentAt<=time
RETURN time, avg(response.sentAt-offloaded.sentAt) as value
ORDER BY time
`

const getBarChartDbResult = async (alg, isFailureRun) => {
    const result = {};
    const filteredDbs =
        databases
            .filter(db => isFailureRun ? db.endsWith("-fail") : !db.endsWith("-fail"))
            .filter(db => db.startsWith(alg));
    const query = alg.startsWith('gossips') ? GOSSIPS_BAR_QUERY : ACO_RW_BAR_QUERY;
    for (const db of filteredDbs) {
        const amountNodes = extractAmountNodesByDB(db);
        const session = createSession(db);
        const queryResult = await session.run(query);
        result[amountNodes] = queryResult.records[0].get(0) / 1000;
        await session.close();
    }
    return result;
};

const getTimeChartDbResult = async (db) => {
    const session = createSession(db);
    const queryResult = await session.run(ACO_RW_TIME_QUERY);
    const result = queryResult.records
        .map(record => {
            const timestamp = record.get(0).toString();
            const averageServiceTime = record.get(1) / 1000;
            return {timestamp, averageServiceTime};
        })
        .reduce((map, record) => {
            map[record.timestamp] = record.averageServiceTime;
            return map;
        }, {})
    await session.close();
    return convertToRelativeTimestampMap(result);
}

const generateBarChartData = async () => {
    for (const alg of algorithms) {
        const dbResult = await getBarChartDbResult(alg, false);
        writeBarChartCsvFile(`data/service_time/${alg}.csv`, dbResult);

        const dbFailResult = await getBarChartDbResult(alg, true);
        writeBarChartCsvFile(`data/service_time/${alg}-fail.csv`, dbFailResult);
    }
};

const generateTimeChartData = async () => {
    for (const db of databases) {
        if (db.startsWith('gossips-')) {
            continue;
        }
        const alg = extractAlgByDB(db);
        const amountNodes = extractAmountNodesByDB(db);
        const dbResult = await getTimeChartDbResult(db);
        if (db.endsWith("-fail")) {
            writeTimeChartCsvFile(`data/service_time/${alg}-n${amountNodes}-time-fail.csv`, dbResult);
        } else {
            writeTimeChartCsvFile(`data/service_time/${alg}-n${amountNodes}-time.csv`, dbResult);
        }
    }
};

const generateAverageTimeChartData = async (averageQuery, query, db) => {
    const session = createSession(db);
    const averageQueryResult = await session.run(averageQuery);
    const averageValue = averageQueryResult.records[0].get(0) / 1000;
    const queryResult = await session.run(query);
    const result = queryResult.records
        .map(record => {
            const timestamp = record.get(0).toString();
            return {timestamp, averageValue};
        })
        .reduce((map, record) => {
            map[record.timestamp] = record.averageValue;
            return map;
        }, {})
    await session.close();
    const map = convertToRelativeTimestampMap(result);
    const alg = extractAlgByDB(db);
    const amountNodes = extractAmountNodesByDB(db);
    writeTimeChartCsvFile(`data/service_time/${alg}-n${amountNodes}-time-average.csv`, map)
};

const run = async () => {
    await generateBarChartData();
    await generateAverageTimeChartData(ACO_RW_BAR_QUERY, ACO_RW_TIME_QUERY, 'aco-100')
    await generateTimeChartData();
    console.log('FINISHED')
};

run().then().catch(console.error)
