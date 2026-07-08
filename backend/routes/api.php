<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\ItemController;
use App\Http\Controllers\ClaimController;
use App\Http\Controllers\AdminController;

// Public authentication routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/verify-otp', [AuthController::class, 'verifyOtp']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);

// Public listings
Route::get('/items', [ItemController::class, 'index']);
Route::get('/items/{id}', [ItemController::class, 'show']);
Route::get('/history', [ItemController::class, 'history']);

// Protected routes (requires token)
Route::middleware('auth:sanctum')->group(function () {
    // Auth profile
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'profile']);
    Route::post('/user/update', [AuthController::class, 'updateProfile']);

    // Items CRUD and user listings
    Route::post('/items', [ItemController::class, 'store']);
    Route::put('/items/{id}', [ItemController::class, 'update']);
    Route::delete('/items/{id}', [ItemController::class, 'destroy']);
    Route::get('/my-items', [ItemController::class, 'myItems']);

    // Claims operations
    Route::post('/items/{itemId}/claim', [ClaimController::class, 'store']);
    Route::get('/my-claims', [ClaimController::class, 'myClaims']);
    Route::get('/items/{itemId}/claims', [ClaimController::class, 'itemClaims']);
    Route::put('/claims/{id}/status', [ClaimController::class, 'updateStatus']);

    // Admin Operations
    Route::prefix('admin')->group(function () {
        Route::get('/stats', [AdminController::class, 'stats']);
        Route::get('/users', [AdminController::class, 'users']);
        Route::delete('/users/{id}', [AdminController::class, 'deleteUser']);
        Route::get('/items', [AdminController::class, 'items']);
        Route::delete('/items/{id}', [AdminController::class, 'deleteItem']);
        Route::get('/claims', [AdminController::class, 'claims']);
        Route::put('/claims/{id}/status', [AdminController::class, 'updateClaimStatus']);
    });
});
