"""
Custom permission classes.
"""

from rest_framework import permissions


class IsAdmin(permissions.BasePermission):
    """Allow access only to society admins."""

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.is_admin
        )


class IsMaker(permissions.BasePermission):
    """Allow access to makers."""

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.is_maker
        )


class IsChecker(permissions.BasePermission):
    """Allow access to checkers."""

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.is_checker
        )


class IsApprover(permissions.BasePermission):
    """Allow access to approvers."""

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.is_approver
        )


class IsSecurityGuard(permissions.BasePermission):
    """Allow access only to security guards."""

    def has_permission(self, request, view):
        return (
            request.user
            and request.user.is_authenticated
            and request.user.role == "security_guard"
        )
