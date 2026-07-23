import { test, expect } from '@playwright/test';

test.describe('User Registration and Login Flow', () => {
  test('should register new user', async ({ page }) => {
    await page.goto('http://localhost:3000/register');

    await page.fill('input[name="email"]', 'newuser@example.com');
    await page.fill('input[name="username"]', 'newuser');
    await page.fill('input[name="password"]', 'SecurePass123!');

    await page.click('button[type="submit"]');

    await expect(page).toHaveURL(/.*dashboard/);
  });

  test('should login existing user', async ({ page }) => {
    await page.goto('http://localhost:3000/login');

    await page.fill('input[name="email"]', 'test@example.com');
    await page.fill('input[name="password"]', 'password123');

    await page.click('button[type="submit"]');

    await expect(page).toHaveURL(/.*dashboard/);
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await page.goto('http://localhost:3000/login');

    await page.fill('input[name="email"]', 'invalid@example.com');
    await page.fill('input[name="password"]', 'wrongpassword');

    await page.click('button[type="submit"]');

    await expect(page.locator('.error-message')).toBeVisible();
  });

  test('should logout user', async ({ page }) => {
    await page.goto('http://localhost:3000/dashboard');

    await page.click('button#logout');

    await expect(page).toHaveURL(/.*login/);
  });
});

test.describe('User Profile Management', () => {
  test('should update user profile', async ({ page }) => {
    await page.goto('http://localhost:3000/profile');

    await page.fill('input[name="firstName"]', 'John');
    await page.fill('input[name="lastName"]', 'Doe');

    await page.click('button[type="submit"]');

    await expect(page.locator('.success-message')).toBeVisible();
  });

  test('should change password', async ({ page }) => {
    await page.goto('http://localhost:3000/settings/security');

    await page.fill('input[name="currentPassword"]', 'password123');
    await page.fill('input[name="newPassword"]', 'newPassword456!');
    await page.fill('input[name="confirmPassword"]', 'newPassword456!');

    await page.click('button[type="submit"]');

    await expect(page.locator('.success-message')).toBeVisible();
  });
});
