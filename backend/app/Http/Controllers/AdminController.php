<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Item;
use App\Models\Claim;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AdminController extends Controller
{
    private function checkAdmin(Request $request)
    {
        if (!$request->user() || !$request->user()->is_admin) {
            abort(response()->json(['message' => 'Unauthorized: Administrator access required'], 403));
        }
    }

    public function stats(Request $request)
    {
        $this->checkAdmin($request);

        $totalUsers = User::where('is_admin', false)->count();
        $totalLost = Item::where('type', 'lost')->count();
        $totalFound = Item::where('type', 'found')->count();
        $totalReturned = Item::where('status', 'returned')->count();
        
        $claimsPending = Claim::where('status', 'pending')->count();
        $claimsApproved = Claim::where('status', 'approved')->count();
        $claimsRejected = Claim::where('status', 'rejected')->count();

        return response()->json([
            'users_count' => $totalUsers,
            'lost_count' => $totalLost,
            'found_count' => $totalFound,
            'returned_count' => $totalReturned,
            'claims' => [
                'pending' => $claimsPending,
                'approved' => $claimsApproved,
                'rejected' => $claimsRejected,
                'total' => $claimsPending + $claimsApproved + $claimsRejected
            ]
        ]);
    }

    public function users(Request $request)
    {
        $this->checkAdmin($request);

        $users = User::where('is_admin', false)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($users);
    }

    public function deleteUser(Request $request, $id)
    {
        $this->checkAdmin($request);

        $user = User::find($id);

        if (!$user) {
            return response()->json(['message' => 'User not found'], 404);
        }

        if ($user->is_admin) {
            return response()->json(['message' => 'Cannot delete an administrator account'], 400);
        }

        // Delete user's items and their files
        $items = Item::where('user_id', $user->id)->get();
        foreach ($items as $item) {
            if ($item->image_path) {
                $oldPath = str_replace('storage/', '', $item->image_path);
                Storage::disk('public')->delete($oldPath);
            }
            $item->delete();
        }

        // Delete user's claims
        Claim::where('claimant_id', $user->id)->delete();

        $user->delete();

        return response()->json(['message' => 'User and all related data deleted successfully']);
    }

    public function items(Request $request)
    {
        $this->checkAdmin($request);

        $items = Item::with('user')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($items);
    }

    public function deleteItem(Request $request, $id)
    {
        $this->checkAdmin($request);

        $item = Item::find($id);

        if (!$item) {
            return response()->json(['message' => 'Item not found'], 404);
        }

        if ($item->image_path) {
            $oldPath = str_replace('storage/', '', $item->image_path);
            Storage::disk('public')->delete($oldPath);
        }

        // Delete claims on this item
        Claim::where('item_id', $item->id)->delete();

        $item->delete();

        return response()->json(['message' => 'Report deleted successfully']);
    }

    public function claims(Request $request)
    {
        $this->checkAdmin($request);

        $claims = Claim::with(['claimant', 'item.user'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json($claims);
    }

    public function updateClaimStatus(Request $request, $id)
    {
        $this->checkAdmin($request);

        $claim = Claim::with('item')->find($id);

        if (!$claim) {
            return response()->json(['message' => 'Claim not found'], 404);
        }

        $validated = $request->validate([
            'status' => 'required|in:approved,rejected,pending',
        ]);

        $claim->status = $validated['status'];
        $claim->save();

        // If approved, reject all other pending claims on this item
        if ($validated['status'] === 'approved') {
            Claim::where('item_id', $claim->item_id)
                ->where('id', '!=', $claim->id)
                ->where('status', 'pending')
                ->update(['status' => 'rejected']);
        }

        return response()->json([
            'message' => 'Claim status updated successfully',
            'claim' => $claim
        ]);
    }
}
