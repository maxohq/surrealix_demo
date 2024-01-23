/**
 * Generator base class
 * - provides basic functions to help with code generation
 */

type FileType = "ex" | "ts";
export class GenBase {
    logLevel = 1; // change for more verbose logging
    lines: string[] = [];
    indentLevel = 0;
    prefix = "";
    generatorName = "";

    get content() {
        return this.lines.join("\n");
    }

    push(line: string) {
        this.lines.push(this.prefix + line);
    }
    plainPush(line: string) {
        this.lines.push(line);
    }
    indentUp(amount = 1) {
        this.indentLevel += amount;
        this.setPrefix();
    }

    indentDown(amount = 1) {
        this.indentLevel -= amount;
        this.setPrefix();
    }

    setPrefix() {
        this.prefix = Array(this.indentLevel).fill("  ").join("");
    }

    withIndent(func: () => void) {
        this.indentUp();
        func();
        this.indentDown();
    }

    addBanner(type: FileType) {
        if (type === "ts") {
            this.push(
                `// **** GENERATED CODE! see ${this.generatorName} for details. ****`
            );
        }
        if (type === "ex") {
            this.push(
                `## **** GENERATED CODE! see ${this.generatorName} for details. ****`
            );
        }
        this.push("");
    }

    logRun() {
        this.log(`*** RUN GENERATOR ${this.generatorName}`);
    }

    log(...s: unknown[]) {
        console.log(...s);
    }

    warn(...s: unknown[]) {
        if (this.logLevel < 2) {
            return;
        }
        this.log(...s);
    }

    debug(...s: unknown[]) {
        if (this.logLevel < 3) {
            return;
        }
        this.log(...s);
    }
}