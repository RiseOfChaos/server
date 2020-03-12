CREATE TABLE Player
(
    id       serial PRIMARY KEY,
    username text UNIQUE,
    email    text UNIQUE,
    password text
);

CREATE TYPE Resources AS
(
    adamantium int,
    magnetite  int,
    uranium    int
);

CREATE TYPE TimedResources AS
(
    was  Resources,
    rate Resources,
    at   timestamp,
    max  Resources
);

CREATE TYPE Troops AS
(
    brutes        int,
    viper         int,
    alphaGuardian int,
    plasmaRanger  int,
    stingray      int,
    blaster       int,
    catapult      int
);

CREATE TYPE Plot AS
(
    type  int,
    level int,
    pos   int
);

CREATE TYPE ConstructionType AS ENUM (
    'construction',
    'upgrade',
    'downgrade',
    'demolish'
    );

CREATE TYPE Construction AS
(
    id               text,
    pos              int,
    buildingType     int,
    constructionType ConstructionType,
    startedAt        timestamp,
    finishesAt       timestamp
);

CREATE TYPE Recruitment AS
(
    id         text,
    type       int,
    amount     int,
    startedAt  timestamp,
    finishesAt timestamp,
    duration   int,
    resources  Resources
);

CREATE TYPE Trade AS
(
    id          text,
    carts       int,
    resources   Resources,
    fromId      text,
    toId        text,
    isReturning boolean,
    startedAt   timestamp,
    finishesAt  timestamp
);

CREATE TYPE TradeIn AS
(
    id        text,
    resources Resources,
    fromId    text,
    toId      text,
    arrivesAt timestamp
);

CREATE TYPE CommandType AS ENUM (
    'loot',
    'support',
    'plunder',
    'assault',
    'siege'
    );

CREATE TYPE CommandState AS ENUM (
    'going',
    'returning',
    'staying'
    );

CREATE TYPE Command AS
(
    id         text,
    type       CommandType,
    troops     Troops,
    fromId     text,
    toId       text,
    loot       Resources,
    startedAt  timestamp,
    finishesAt timestamp,
    state      CommandState
);

CREATE TYPE OnSupport AS
(
    id        text,
    fromId    text,
    troops    Troops,
    arrivesAt timestamp
);

CREATE TYPE IncomingAtttack AS
(
    id     text,
    fromId text,
    hitAt  timestamp
);

CREATE TYPE BuildingCache AS
(
    hotpoints             int,
    numBuildings          int,
    score                 int,
    castled               boolean,
    buildingsByType       jsonb,
    troopSpace            int,
    constructionSpeed     int,
    carts                 int,
    recruitable           hstore,
    meleeRecruitmentSpeed int,
    rangeRecruitmentSpeed int,
    siegeRecruitmentSpeed int
);

CREATE TABLE City
(
    id              serial PRIMARY KEY NOT NULL,
    pos             point              NOT NULL,
    continent       text               NOT NULL,
    ownerId         int references Player (id),
    level           int                NOT NULL,
    plots           jsonb              NOT NULL,
    constructions   Construction[]     NOT NULL,
    recruitments    Recruitment[]      NOT NULL,
    trades          Trade[]            NOT NULL,
    tradeIns        TradeIn[]          NOT NULL,
    commands        Command[]          NOT NULL,
    onSupports      OnSupport[]        NOT NULL,
    incomingAttacks IncomingAtttack[]  NOT NULL,
    resources       TimedResources     NOT NULL,
    totalCS         int                NOT NULL,
    buildingCache   BuildingCache      NOT NULL,
    troopsHome      Troops             NOT NULL
);