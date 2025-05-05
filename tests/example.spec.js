// @ts-check
import { test, expect } from "@playwright/test";

test("has title", async ({ page }) => {
	await page.goto("http://localhost:9292");

	// Expect a title "to contain" a substring.
	await expect(page.locator("body")).toContainText("Hello world!");
});

test("admin redirects to login", async ({ page }) => {
	await page.goto("http://localhost:9292/admin");
	await expect(page).toHaveURL("http://localhost:9292/login?redirect=/admin");
});

test("login works", async ({ page }) => {
	await page.goto("http://localhost:9292/login");
	await page.locator('input[name="email"]').fill("admin@example.com");
	await page.locator('input[name="password"]').fill("password");
	await page.locator('button[type="submit"]').click();
	await page.goto("http://localhost:9292/admin");
	await expect(page).toHaveURL("http://localhost:9292/admin");
});

test("signup, logout, login works", async ({ page }) => {
	await page.goto("http://localhost:9292/signup");
	await page.locator('input[name="email"]').fill("test@example.com");
	await page.locator('input[name="password"]').fill("password");
	await page.locator('input[name="username"]').fill("testuser");
	await page.locator('button[type="submit"]').click();
	await page.goto("http://localhost:9292/admin");
	await expect(page).toHaveURL("http://localhost:9292/login?redirect=/admin");
	await page.goto("http://localhost:9292/logout");
	await page.goto("http://localhost:9292/login");
	await page.locator('input[name="email"]').fill("test@example.com");
	await page.locator('input[name="password"]').fill("password");
	await page.locator('button[type="submit"]').click();
	await page.goto("http://localhost:9292/admin");
	await expect(page).toHaveURL("http://localhost:9292/login?redirect=/admin");
});
