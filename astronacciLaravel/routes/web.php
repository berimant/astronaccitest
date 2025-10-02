<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| These routes are loaded by the RouteServiceProvider and all of them will
| receive the "web" middleware group.
|
*/

Route::get('/', function () {
    return view('welcome');
});
