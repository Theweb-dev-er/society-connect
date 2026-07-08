"""
Cursor pagination for large datasets.
"""

from rest_framework.pagination import CursorPagination as DRF_CursorPagination


class CursorPagination(DRF_CursorPagination):
    """
    Cursor-based pagination for O(1) deep-page performance.
    Use with ordering on a unique or nearly-unique field.
    """

    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100
    ordering = "-created_at"
