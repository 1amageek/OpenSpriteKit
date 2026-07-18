import { test, expect, type Page } from "@playwright/test";

// OpenSpriteKit E2E — Swift Testing ABI v0 drives the assertions.
//
// The WASM module's `setup()` boots the scene, attaches the WebGPU
// renderer, then hands control to `BrowserTestRunner.run()` (from
// swift-wasm-testing). The runner executes every `@Test` function in
// the module, streams JSON records into `window.__wasm_tests.records`,
// and flips `window.__wasm_tests.done = true` when finished.
//
// This spec is therefore a thin driver: wait for completion, print the
// record stream for diagnostics, and fail the Playwright test iff any
// @Test recorded a failure (or the runner itself threw).

interface WasmTestsState {
    done: boolean;
    success: boolean;
    error: string | null;
    records: string[];
}

async function waitForWasmTests(page: Page): Promise<WasmTestsState> {
    await page.waitForFunction(
        () => {
            const t = (window as unknown as { __wasm_tests?: { done?: boolean } }).__wasm_tests;
            return !!t && t.done === true;
        },
        null,
        { timeout: 45_000 }
    );
    return await page.evaluate((): WasmTestsState => {
        const t = (window as unknown as { __wasm_tests: WasmTestsState }).__wasm_tests;
        return {
            done: t.done,
            success: t.success,
            error: t.error,
            records: t.records,
        };
    });
}

test("swift-testing: all @Test functions pass under WebGPU + rAF", async ({ page }) => {
    page.on("console", (msg) => console.log(`[page:${msg.type()}]`, msg.text()));
    page.on("pageerror", (err) => console.error("[pageerror]", err.message));

    await page.goto("/");
    const state = await waitForWasmTests(page);

    console.log("----- swift-testing records -----");
    const failureMessages: string[] = [];
    for (const raw of state.records) {
        try {
            const rec = JSON.parse(raw);
            console.log(JSON.stringify(rec));
            if (rec.kind === "event" && rec.payload?.kind === "issueRecorded") {
                const msg = rec.payload?.issue?.sourceContext?.message
                    ?? rec.payload?.messages?.map((m: { text: string }) => m.text).join("; ")
                    ?? raw;
                failureMessages.push(typeof msg === "string" ? msg : JSON.stringify(msg));
            }
        } catch {
            console.log("[unparsable]", raw);
        }
    }
    console.log("---------------------------------");
    console.log(`runner: success=${state.success} error=${state.error ?? "null"} records=${state.records.length}`);

    expect(state.error, "runner must not throw").toBeNull();
    expect(
        state.success,
        `swift-testing reported failures. Issues:\n${failureMessages.join("\n")}`
    ).toBe(true);

    const pixels = await page.evaluate(async () => {
        const canvas = document.querySelector<HTMLCanvasElement>("#osk-canvas");
        if (!canvas) throw new Error("OpenSpriteKit canvas is missing");
        const blob = await new Promise<Blob>((resolve, reject) => {
            canvas.toBlob(
                (result) => result ? resolve(result) : reject(new Error("canvas capture failed")),
                "image/png"
            );
        });
        const bitmap = await createImageBitmap(blob);
        const copy = document.createElement("canvas");
        copy.width = canvas.width;
        copy.height = canvas.height;
        const context = copy.getContext("2d");
        if (!context) throw new Error("2D readback context is unavailable");
        context.drawImage(bitmap, 0, 0);
        bitmap.close();

        const sample = (x: number, y: number) =>
            Array.from(context.getImageData(x, y, 1, 1).data);
        return {
            background: sample(10, 10),
            red: sample(80, 150),
            green: sample(200, 150),
            blue: sample(320, 150),
        };
    });

    expect(pixels.background[0]).toBeGreaterThanOrEqual(15);
    expect(pixels.background[0]).toBeLessThan(45);
    expect(pixels.background[1]).toBeLessThan(45);
    expect(pixels.background[2]).toBeGreaterThan(pixels.background[0]);
    expect(pixels.red[0]).toBeGreaterThan(220);
    expect(pixels.red[1]).toBeLessThan(40);
    expect(pixels.red[2]).toBeLessThan(40);
    expect(pixels.green[0]).toBeLessThan(40);
    expect(pixels.green[1]).toBeGreaterThan(220);
    expect(pixels.green[2]).toBeLessThan(40);
    expect(pixels.blue[0]).toBeLessThan(40);
    expect(pixels.blue[1]).toBeLessThan(40);
    expect(pixels.blue[2]).toBeGreaterThan(220);
});
