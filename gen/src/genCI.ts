const yaml = require("js-yaml");
const fs = require("fs");

const setupElixirSteps = [
  {
    name: "Cache deps",
    id: "cache-deps",
    uses: "actions/cache@v3",
    env: {
      "cache-name": "cache-elixir-deps",
    },
    with: {
      path: "deps",
      key: "${{ runner.os }}-mix-${{ env.MIX_ENV }}-${{ env.cache-name }}-${{ hashFiles('mix.lock') }}",
      "restore-keys": "${{ runner.os }}-mix-${{ env.MIX_ENV }}-${{ env.cache-name }}-\n",
    },
  },
  {
    name: "Cache compiled build",
    id: "cache-build",
    uses: "actions/cache@v3",
    env: {
      "cache-name": "cache-compiled-build",
    },
    with: {
      path: "_build",
      key: "${{ runner.os }}-mix-${{ env.MIX_ENV }}-${{ env.cache-name }}-${{ hashFiles('mix.lock') }}",
      "restore-keys":
        "${{ runner.os }}-mix-${{ env.MIX_ENV }}-${{ env.cache-name }}-\n${{ runner.os }}-mix-${{ env.MIX_ENV }}-\n${{ runner.os }}-mix\n",
    },
  },
  {
    name: "Set up Elixir",
    uses: "erlef/setup-beam@v1",
    with: {
      "elixir-version": "1.16.0",
      "otp-version": "26.1.2",
    },
  },
  {
    name: "Install dependencies",
    run: "mix deps.get",
  },
  {
    name: "Setup .env file",
    run: "bin/ci-setup.sh",
  },
];
const checkoutSteps = [
  {
    uses: "actions/checkout@v3",
  },
];

const startSurrealSteps = [
  {
    name: "Start SurrealDB docker image",
    run: "bin/ci-docker-surreal-restart.sh",
  },
];

const stopSurrealSteps = [
  {
    name: "Stop SurrealDB docker image",
    run: "bin/ci-docker-surreal-stop.sh",
  },
];


const checkElixirFmt = [
  {
    name: "Run format check",
    run: "mix format --check-formatted",
  },
]

const compileElixirCode = [
  {
    name: "Compile Elixir code",
    run: "mix compile",
  },
]

const runElixirTest = [
  {
    name: "Run Elixir tests",
    run: "mix test",
  },
]

const testEnv = {
  MIX_ENV: "test",
  ELIXIR_ENV: "test",
  DATABASE_HOST: "localhost",
  DATABASE_USER: "postgres",
  DATABASE_PORT: 5432,
  DATABASE_PASSWORD: "postgres",
};

const postgresService = {
  image: "postgres:15.4",
  env: {
    POSTGRES_PASSWORD: "postgres",
  },
  ports: ["5432:5432"],
  options: "--health-cmd pg_isready --health-interval 10s --health-timeout 5s --health-retries 5",
};

const job = {
  name: "CI",
  on: {
    push: {
      // branches: ['main'],
    },
    pull_request: {},
  },
  jobs: {
    "mix-format": {
      name: "Mix Format",
      "runs-on": "ubuntu-latest",
      env: testEnv,
      steps: [
        ...checkoutSteps,
        ...setupElixirSteps,
        // first we check fmt, if that fails, we do not need to run expensive compile step
        ...checkElixirFmt,
        // we compile here, that way cache is reusable for tests, even if they fail!
        ...compileElixirCode,
      ],
    },
    "mix-test": {
      name: "Mix Test",
      "runs-on": "ubuntu-latest",
      // wait until mix-format finishes, so we can reuse the caches!
      needs: "mix-format",
      env: testEnv,
      services: {
        postgres: postgresService,
      },
      steps: [
        ...checkoutSteps,
        ...setupElixirSteps,
        ...startSurrealSteps,
        ...runElixirTest,
        ...stopSurrealSteps,
      ],
    },
  },
};

// console.log(import.meta.dir);
const ciYamlPath = `${import.meta.dir}/../../.github/workflows/ci.yml`;

class GeneratorCI {
  run() {
    const output = yaml.dump(job, { noRefs: true });
    const banner = "### GENERATED by gen/genCI.ts!\n\n";
    const fullContent = banner + output;
    console.log(fullContent);
    fs.writeFileSync(ciYamlPath, fullContent, "utf8");
  }

  dumpCurrent() {
    try {
      const doc = yaml.load(fs.readFileSync(ciYamlPath, "utf8"));
      const res = JSON.stringify(doc, null, 2);
      console.log(res);
    } catch (e) {
      console.log(e);
    }
  }
}

const generator = new GeneratorCI();
generator.run();
// generator.dumpCurrent();
